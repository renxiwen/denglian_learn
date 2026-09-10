// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBank {
    function deposit() external payable;
    function withdraw() external;
    function transferAdmin(address newAdmin) external;
}
