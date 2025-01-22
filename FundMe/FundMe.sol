// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


error notOwner();


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal  view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmmountInUsd = (ethPrice * ethAmmount) / 1e18;
        return ethAmmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version();
    }
}

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You don't have enought currency to execute this transaction!");
        funders.push(msg.sender);
        addressToAmmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public only_Owner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    modifier only_Owner() {
        //require(msg.sender == i_owner, "Must be i_owner!");
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
