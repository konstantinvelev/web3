// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    uint256 public minimumUsd = 5;

    // function fund() public payazble {
    //     require(msg.value >= minimumUsd, "You don't have enought currency to execute this transaction!");
    // }

    function withdraw() public {

    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface myAgg = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return myAgg.version();
    }

    function getVersion() public view returns(uint256) {
        return  AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }

    function getConversionRate() public {

    }
}
