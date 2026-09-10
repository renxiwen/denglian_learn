// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IBank.sol";

contract Admin {
    address public owner;

    event AdminWithdraw(address indexed bank, uint amount);
    event OwnerWithdraw(address indexed owner, uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Admin: caller is not owner");
        _;
    }

    // 必须实现 receive() 回退函数以接收来自 Bank 转移的 ETH
    receive() external payable {}

    // 调用 IBank 接口的 withdraw 方法，把 bank 合约内的资金转移到本 Admin 合约地址
    function adminWithdraw(IBank bank) external onlyOwner {
        bank.withdraw();
        emit AdminWithdraw(address(bank), address(this).balance);
    }

    // 将 Admin 合约内的资金提取给 Owner 地址
    function withdrawToOwner() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Admin: no balance");
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "Admin: transfer failed");
        emit OwnerWithdraw(owner, amount);
    }
}
