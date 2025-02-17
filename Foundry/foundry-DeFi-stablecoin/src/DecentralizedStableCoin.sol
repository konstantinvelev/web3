// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__NotEnoughBalance();
    error DecentralizedStableCoin__InvalidAmount();
    error DecentralizedStableCoin__InvalidAddress();

    modifier validAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert DecentralizedStableCoin__InvalidAmount();
        }
        _;
    }

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner validAmount(_amount) {
        uint256 balance = balanceOf(msg.sender);
        if (balance < _amount) {
            revert DecentralizedStableCoin__NotEnoughBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner validAmount(_amount) returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__InvalidAddress();
        }

        _mint(_to, _amount);
        return true;
    }
}
