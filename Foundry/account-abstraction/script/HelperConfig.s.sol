// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    uint256 private constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 private constant LOCAL_CHAIN_ID = 31337;
    address private constant BURNER_WALLET = 0x7332bd1E178d8f9C29054Ac924e1B76b1792c76B;
    //address private constant FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address private constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig networks) networkConfigs;

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaNetworkConfig();
        } else if (block.chainid == ZKSYNC_SEPOLIA_CHAIN_ID) {
            networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZKSyncSepoliaNetworkConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilNetworkConfig();
        }
        activeNetworkConfig = networkConfigs[block.chainid];
    }

    function getEthSepoliaNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, account: BURNER_WALLET});
    }

    function getZKSyncSepoliaNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.account != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        return NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_DEFAULT_ACCOUNT});
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
