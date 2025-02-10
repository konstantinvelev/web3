// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundInteraction is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function sendFund(address mostRecentlyContract) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyContract)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyContract = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        sendFund(mostRecentlyContract);
    }
}

contract WithdrawInteraction is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function sendWithdraw(address mostRecentlyContract) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyContract)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyContract = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        sendWithdraw(mostRecentlyContract);
    }
}
