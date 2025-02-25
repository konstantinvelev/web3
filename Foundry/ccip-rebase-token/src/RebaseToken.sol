// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {console} from "forge-std/console.sol";

/**
 * @title RebaseToken
 * @author Kontantin Velev
 * @dev Implementation of the Rebase Token
 * @notice This is a cross-chain ERC20 rebase token with the name "Rebase Token"
 */
contract RebaseToken is ERC20, AccessControl, Ownable {
    error RebaseToken__NewInterestRateIsLowerThanCurrent(uint256 currentRate, uint256 newRate);
    error RebaseToken__InvalidAmount(uint256 amount);
    error RebaseToken__InvalidAddress(address addressSender);
    error RebaseToken__InvalidIncreaseOfBalance(uint256 invalidBalance);

    uint256 private constant PRECISION = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = 5e10;
    mapping(address user => uint256 rate) private s_userInterestRate;
    mapping(address user => uint256 lastUpdatedTimestamp) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 indexed _interestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    modifier validAmount(uint256 amount) {
        if (amount <= 0) {
            console.log("hit");
            revert RebaseToken__InvalidAmount(amount);
        }
        _;
    }

    modifier validAddress(address addressSender) {
        if (addressSender == address(0)) {
            revert RebaseToken__InvalidAddress(addressSender);
        }
        _;
    }

    function grantMintAndBurnRole(address account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, account);
    }

    /**
     * @dev Function to set the interest rate
     * @param _interestRate The new interest rate
     */
    function setInterestRate(uint256 _interestRate) external onlyOwner {
        if (_interestRate > s_interestRate) {
            revert RebaseToken__NewInterestRateIsLowerThanCurrent(s_interestRate, _interestRate);
        }
        s_interestRate = _interestRate;
        emit InterestRateSet(_interestRate);
    }

    function mint(address to, uint256 amount, uint256 userInterestRate)
        external
        validAddress(to)
        validAmount(amount)
        onlyRole(MINT_AND_BURN_ROLE)
    {
        _mintAccruedInterest(to);
        s_userInterestRate[to] = userInterestRate;
        _mint(to, amount);
    }

    function burn(address from, uint256 amount)
        external
        validAddress(from)
        validAmount(amount)
        onlyRole(MINT_AND_BURN_ROLE)
    {
        _mintAccruedInterest(from);
        _burn(from, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        validAddress(recipient)
        validAmount(amount)
        returns (bool)
    {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(recipient);
        if (amount == type(uint256).max) {
            amount = balanceOf(msg.sender);
        }

        if (balanceOf(recipient) == 0) {
            s_userInterestRate[recipient] = s_userInterestRate[msg.sender];
        }

        return super.transfer(recipient, amount);
    }

    function transferFrom(address from, address recipient, uint256 amount)
        public
        override
        validAddress(from)
        validAddress(recipient)
        validAmount(amount)
        returns (bool)
    {
        _mintAccruedInterest(from);
        _mintAccruedInterest(recipient);
        if (amount == type(uint256).max) {
            amount = balanceOf(from);
        }

        if (balanceOf(recipient) == 0) {
            s_userInterestRate[recipient] = s_userInterestRate[from];
        }

        return super.transferFrom(from, recipient, amount);
    }

    //internal functions
    function _mintAccruedInterest(address user) internal validAddress(user) {
        uint256 previosPrincipleBalance = super.balanceOf(user);
        uint256 currentBalance = balanceOf(user);
        uint256 increaseBalance = currentBalance - previosPrincipleBalance;
        _mint(user, increaseBalance);
        s_userLastUpdatedTimestamp[user] = block.timestamp;
    }

    function balanceOf(address user) public view override returns (uint256) {
        uint256 currentPrincipalBalance = super.balanceOf(user);
        if (currentPrincipalBalance == 0) {
            return 0;
        }
        return (currentPrincipalBalance * _calculateUserAccumulatedInterestSinceLastUpdate(user)) / PRECISION;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address user)
        internal
        view
        returns (uint256 linearInterest)
    {
        uint256 timePassed = block.timestamp - s_userLastUpdatedTimestamp[user];
        linearInterest = (s_userInterestRate[user] * timePassed) + PRECISION;
    }

    //view functions
    function pincipleBalanceOf(address user) external view returns (uint256) {
        return super.balanceOf(user);
    }

    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
