// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract Handler is Test {
    DecentralizedStableCoin dsc;
    DSCEngine engine;

    ERC20Mock weth;
    ERC20Mock wbtc;
    MockV3Aggregator wethUsdPriceFeed;

    address[] public usersWithCollateral;
    uint256 public timesMintIsCalled = 0;
    uint256 MAX_DEPOSITE_SIZE = type(uint96).max;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;

        address[] memory tokens = engine.getCollateralTokens();
        weth = ERC20Mock(tokens[0]);
        wbtc = ERC20Mock(tokens[1]);

        wethUsdPriceFeed = MockV3Aggregator(engine.getCollateralTokenPriceFeed(tokens[0]));
    }

    function depostiCollateral(uint256 collateralSeed, uint256 amount) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amount = bound(amount, 1, MAX_DEPOSITE_SIZE);
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amount);
        collateral.approve(address(engine), amount);
        engine.depositCollateral(address(collateral), amount);
        vm.stopPrank();
        usersWithCollateral.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amount) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralRedeem = engine.getMaxCollateralRedeem(address(collateral), msg.sender);
        amount = bound(amount, 0, maxCollateralRedeem);
        if (amount == 0) {
            return;
        }
        engine.redeemCollateral(address(collateral), amount);
    }

    function mintDSC(uint256 amount, uint256 userSeed) public {
        if (usersWithCollateral.length == 0) {
            return;
        }
        address sender = usersWithCollateral[userSeed % usersWithCollateral.length];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(sender);
        uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted;
        if (maxDscToMint < 0) {
            return;
        }

        amount = bound(amount, 0, maxDscToMint);
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        engine.mintDsc(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    // function updateCollateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     wethUsdPriceFeed.setLatestPrice(price);
    // }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }

    function _getUserFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
