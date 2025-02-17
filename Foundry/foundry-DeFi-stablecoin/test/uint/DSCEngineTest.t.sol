// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract DSCEngineTest is Test {
    DeployDSC s_deployer;
    DecentralizedStableCoin s_dsc;
    DSCEngine s_engine;
    HelperConfig s_helper;
    address s_ethUsdPriceFeed;
    address s_btcUsdPriceFeed;
    address s_weth;

    address private USER = makeAddr("user");
    uint256 private constant AMMOUNT_COLLATERAL = 10 ether;
    uint256 private constant STARTING_ERC20_BALANCE = 10 ether;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    function setUp() external {
        s_deployer = new DeployDSC();
        (s_dsc, s_engine, s_helper) = s_deployer.run();
        (s_ethUsdPriceFeed, s_btcUsdPriceFeed, s_weth,,) = s_helper.activeNetworkConfig();

        ERC20Mock(s_weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    ////////////////////////////
    //// Constructor ////
    ////////////////////////////

    function testOwnerIsCorrect() public view {
        assertEq(s_dsc.owner(), address(s_engine));
    }

    function testRevertIfTokensAreNotSameCountAsPriceFeeds() public {
        address[] memory tokens = new address[](1);
        address[] memory priceFeeds = new address[](2);
        tokens[0] = s_weth;
        priceFeeds[0] = s_ethUsdPriceFeed;
        priceFeeds[1] = s_btcUsdPriceFeed;

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddresesAndPriceFeedAddressesMustBeSameLenght.selector);
        new DSCEngine(tokens, priceFeeds, address(s_dsc));
    }

    ////////////////////////////
    /////// Test Price ///////
    ////////////////////////////
    function testGetUsdValue() public view {
        uint256 ethUsdPrice = 15e18;
        uint256 expected = 30000e18;
        uint256 actual = s_engine.getUsdValue(s_weth, ethUsdPrice);

        assertEq(actual, expected);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 expected = 0.05 ether;
        uint256 actual = s_engine.getTokenAmountFromUsd(s_weth, usdAmount);

        assertEq(actual, expected);
    }

    ////////////////////////////
    //// Deposit Collateral ////
    ////////////////////////////
    function testRevertIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(s_weth).approve(address(s_engine), AMMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__InvalidAmountSent.selector);
        s_engine.depositCollateral(s_weth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnapprovalCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__InvalidToken.selector);
        s_engine.depositCollateral(address(ranToken), AMMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(s_weth).approve(address(s_engine), AMMOUNT_COLLATERAL);
        s_engine.depositCollateral(s_weth, AMMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = s_engine.getAccountInformation(USER);

        uint256 expectedDepositAmount = s_engine.getTokenAmountFromUsd(s_weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        assertEq(AMMOUNT_COLLATERAL, expectedDepositAmount);
    }

    function testCanDepositeWithoutMinting() public depositedCollateral {
        assertEq(s_dsc.balanceOf(USER), 0);
    }

    ////////////////////////////
    //// Mint Stablecoin ////
    ////////////////////////////
    function testRevertIfTryMintZero() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__InvalidAmountSent.selector);
        s_engine.mintDsc(0.0 ether);
        vm.stopPrank();
        s_dsc.balanceOf(USER);
    }

    function testMintStableCoin() public depositedCollateral {
        vm.startPrank(USER);
        s_engine.mintDsc(0.01 ether);
        vm.stopPrank();
        s_dsc.balanceOf(USER);
    }

    function testCantMintWithoutDeposited() public {
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHeathFactor.selector, 0));
        s_engine.mintDsc(0.01 ether);
        vm.stopPrank();
    }

    ////////////////////////////////////
    //// Deposit & Mint Stablecoin ////
    ////////////////////////////////////

    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(s_weth).approve(address(s_engine), AMMOUNT_COLLATERAL);
        s_engine.depositCollateralAndMintDsc(s_weth, 0.01 ether, AMMOUNT_COLLATERAL);
        vm.stopPrank();
        assertEq(s_dsc.balanceOf(USER), AMMOUNT_COLLATERAL);
    }

    // function testDepositAndMintBreaksHealthFactor() public {
    //      vm.startPrank(USER);
    //     ERC20Mock(s_weth).approve(address(s_engine), 0.1 ether);

    //     vm.expectRevert( abi.encodeWithSelector(
    //             DSCEngine.DSCEngine__BreaksHeathFactor.selector,
    //             0
    //         ));
    //     s_engine.depositCollateralAndMintDsc(s_weth, 0.01 ether, AMMOUNT_COLLATERAL);
    //     vm.stopPrank();
    // }

    ///////////////////////////////////
    // redeemCollateralForDsc Tests //
    //////////////////////////////////

    function testRevertsIfRedeemAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(s_weth).approve(address(s_engine), AMMOUNT_COLLATERAL);
        s_engine.depositCollateralAndMintDsc(s_weth, AMMOUNT_COLLATERAL, 0.1 ether);
        vm.expectRevert(DSCEngine.DSCEngine__InvalidAmountSent.selector);
        s_engine.redeemCollateral(s_weth, 0);
        vm.stopPrank();
    }

    //  function testCanRedeemCollateral() public depositedCollateral {
    //     vm.startPrank(USER);
    //     s_engine.redeemCollateral(s_weth, AMMOUNT_COLLATERAL);
    //     uint256 userBalance = ERC20Mock(s_weth).balanceOf(USER);
    //     assertEq(userBalance, AMMOUNT_COLLATERAL);
    //     vm.stopPrank();
    //  }
}
