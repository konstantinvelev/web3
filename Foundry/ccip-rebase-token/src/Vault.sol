// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    error Vault_RedeemedFailed(address user, uint256 amount);

    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 indexed amount);
    event Redeem(address indexed user, uint256 indexed amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    function deposit() external payable {
        uint256 interestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    function redeem(uint256 amount) external payable {
        if (amount == type(uint256).max) {
            amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, amount);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Vault_RedeemedFailed(msg.sender, amount);
        }
        emit Redeem(msg.sender, amount);
    }

    receive() external payable {}

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
