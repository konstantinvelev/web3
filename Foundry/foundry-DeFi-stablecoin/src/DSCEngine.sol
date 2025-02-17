// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "../src/libraries/OracleLib.sol";

contract DSCEngine is ReentrancyGuard {
    /////////////////////////////
    //// Errors ////
    /////////////////////////////
    error DSCEngine__InvalidAmountSent();
    error DSCEngine__InvalidToken();
    error DSCEngine__TokenAddresesAndPriceFeedAddressesMustBeSameLenght();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHeathFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__RedeemFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImporved();

    /////////////////////////////
    //// Types ////
    /////////////////////////////
    using OracleLib for AggregatorV3Interface;

    /////////////////////////////
    //// State Variables ////
    /////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_TRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUC = 10;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => uint256 amountDscToMint) private s_dscMinted;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    /////////////////////////////
    //// Events ////
    /////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event Minted();
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    /////////////////////////////
    //// Modifiers ////
    /////////////////////////////
    modifier validAmount(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__InvalidAmountSent();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__InvalidToken();
        }
        _;
    }

    /////////////////////////////
    //// Functions ////
    /////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddreses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddreses.length) {
            revert DSCEngine__TokenAddresesAndPriceFeedAddressesMustBeSameLenght();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddreses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////////////
    //// External Functions ////
    /////////////////////////////
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        validAmount(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint)
        external
    {
        burnDsc(amountDscToMint);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        validAmount(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDsc(uint256 amountDscToMint) public validAmount(amountDscToMint) nonReentrant {
        s_dscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
        emit Minted();
    }

    function burnDsc(uint256 amount) public validAmount(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        validAmount(debtToCover)
        nonReentrant
    {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        uint256 collateralBonus = (tokenAmountFromDebtCovered * LIQUIDATION_BONUC) / LIQUIDATION_PRECISION;
        uint256 totalColateral = tokenAmountFromDebtCovered + collateralBonus;

        _redeemCollateral(user, msg.sender, collateral, totalColateral);
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);

        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImporved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {}

    /////////////////////////////
    ////Private Functions/////
    /////////////////////////////

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 collateralAmount)
        private
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= collateralAmount;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, collateralAmount);
        bool success = IERC20(tokenCollateralAddress).transfer(to, collateralAmount);
        if (!success) {
            revert DSCEngine__RedeemFailed();
        }
    }

    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_dscMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHeathFactor(userHealthFactor);
        }
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInfo(user);
        //totalDscMinted is 10 eth
        //collateralValueInUsd is 0.01 eth
        // (0.01 * 50 ) / 100 = 0.005
        uint256 collateralAdjustedForTreshold = (collateralValueInUsd * LIQUIDATION_TRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForTreshold * PRECISION) / totalDscMinted;
    }

    function _getAccountInfo(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_dscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);

        return (totalDscMinted, collateralValueInUsd);
    }

    /////////////////////////////
    ////Public view Functions/////
    /////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getAccountInformation(address user) external view returns (uint256, uint256) {
        return _getAccountInfo(user);
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getMaxCollateralRedeem(address user, address token) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }
}
