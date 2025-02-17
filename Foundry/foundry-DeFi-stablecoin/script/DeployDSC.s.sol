// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getActiveNetworkConfig();

        tokenAddresses = [config.weth, config.wbtc];
        priceFeedAddresses = [config.wethUsdPriceFeed, config.wbtcUsdPriceFeed];

        vm.startBroadcast(config.deployerKey);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
        return (dsc, engine, helper);
    }
}
