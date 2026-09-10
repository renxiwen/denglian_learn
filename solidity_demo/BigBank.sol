// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Bank.sol";

contract BigBank is Bank {
    // 限制存款金额必须大于 0.001 ether
    modifier minDeposit() {
        require(msg.value > 0.001 ether, "BigBank: deposit must be > 0.001 ether");
        _;
    }

    receive() external payable override minDeposit {
        _deposit(msg.sender, msg.value);
    }

    function deposit() external payable override minDeposit {
        _deposit(msg.sender, msg.value);
    }
}
