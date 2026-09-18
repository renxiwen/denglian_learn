// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @notice ERC20 扩展转账的合约接收者需实现此方法。
interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}
