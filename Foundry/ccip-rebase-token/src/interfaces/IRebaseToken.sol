// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRebaseToken {
    function mint(address to, uint256 amount, uint256 interestRate) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address from) external view returns (uint256);
    function grantMintAndBurnRole(address account) external;
    function getInterestRate() external view returns (uint256);
    function getUserInterestRate(address user) external view returns (uint256);
}
