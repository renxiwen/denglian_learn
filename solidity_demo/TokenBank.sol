// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Token.sol";

contract TokenBank {
    Token public token;
    mapping(address => uint) public deposits;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);

    constructor(Token _token) {
        require(address(_token) != address(0), "TokenBank: zero token");
        token = _token;
    }

    // 存入前需先对 TokenBank 调用 Token.approve
    function deposit(uint amount) external {
        require(amount > 0, "TokenBank: zero deposit");
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "TokenBank: transferFrom failed");
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 提取自己之前存入的 token
    function withdraw(uint amount) external {
        require(amount > 0, "TokenBank: zero withdraw");
        require(deposits[msg.sender] >= amount, "TokenBank: insufficient deposit");
        deposits[msg.sender] -= amount;
        bool ok = token.transfer(msg.sender, amount);
        require(ok, "TokenBank: transfer failed");
        emit Withdraw(msg.sender, amount);
    }
}
