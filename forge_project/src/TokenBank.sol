// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TokenBank
/// @notice 通用 ERC20 存款银行。使用 SafeERC20 以兼容主网 USDT 等不返回 bool 的代币。
contract TokenBank {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        require(address(_token) != address(0), "TokenBank: zero token");
        token = _token;
    }

    // 存入前需先对 TokenBank 调用 token.approve（USDT 需注意非零额度覆盖限制）
    function deposit(uint256 amount) external {
        require(amount > 0, "TokenBank: zero deposit");
        token.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 提取自己之前存入的 token
    function withdraw(uint256 amount) external {
        require(amount > 0, "TokenBank: zero withdraw");
        require(deposits[msg.sender] >= amount, "TokenBank: insufficient deposit");
        deposits[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}
