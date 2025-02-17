// // SPDX-License-Identifier:MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract InvariantsTest is StdInvariant, Test{
//     DeployDSC deployer;
//     DecentralizedStableCoin dsc;
//     DSCEngine engine;
//     HelperConfig helper;
//     address weth;
//     address wbtc;

//     function setUp() public {
//         deployer = new DeployDSC();
//         (dsc, engine, helper) = deployer.run();
//         (,, weth, wbtc,) = helper.activeNetworkConfig();

//         targetContract(address(engine));
//     }

//     function invariant_protocolMustHabeMoreValueThanTotalSupply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
//         uint256 totalWBtcDeposited = IERC20(wbtc).balanceOf(address(engine));

//         uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
//         uint256 wbtcValue = engine.getUsdValue(wbtc, totalWBtcDeposited);

//          console.log("Total Supply: ", totalSupply);
//         console.log("totalWethDeposited: ", totalWethDeposited);
//         console.log("totalWBtcDeposited", totalWBtcDeposited);
//         console.log("Weth value: ", wethValue);
//         console.log("WBTC value: ", wbtcValue);

//         assert(wethValue +  wbtcValue >= totalSupply);
//     }

// }
