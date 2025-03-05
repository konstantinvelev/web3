// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimal is Script {
    function run() public returns (MinimalAccount) {
        (, MinimalAccount minimalAccount) = deployMinimalAccount();
        return minimalAccount;
    }

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast(config.account);
        MinimalAccount account = new MinimalAccount(config.entryPoint);
        account.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperConfig, account);
    }
}
