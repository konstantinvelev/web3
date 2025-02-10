// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "src/MyToken.sol";

contract DeployToken is Script {
    uint256 public constant INITAL_SUPPLY = 1000 ether;

    function run() external returns (MyToken) {
        vm.startBroadcast();
        MyToken token = new MyToken(INITAL_SUPPLY);
        vm.stopBroadcast();

        return token;
    }
}
