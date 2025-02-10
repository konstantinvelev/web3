// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSypply) ERC20("MyToken", "OT") {
        _mint(msg.sender, initialSypply);
    }
}
