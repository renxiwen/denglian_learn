// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TokenErc1363.sol";

/// @title TokenBankErc1363
/// @notice 参考 TokenBank.sol，通过 ERC-1363 回调完成单笔存款（无需先 approve 再 deposit）
contract TokenBankErc1363 is IERC1363Receiver, IERC1363Spender {
    TokenErc1363 public token;
    mapping(address => uint) public deposits;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);

    constructor(TokenErc1363 _token) {
        require(address(_token) != address(0), "TokenBankErc1363: zero token");
        token = _token;
    }

    /// @notice 传统存款：需先对 TokenBank 调用 Token.approve
    function deposit(uint amount) external {
        require(amount > 0, "TokenBankErc1363: zero deposit");
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "TokenBankErc1363: transferFrom failed");
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        require(amount > 0, "TokenBankErc1363: zero withdraw");
        require(deposits[msg.sender] >= amount, "TokenBankErc1363: insufficient deposit");
        deposits[msg.sender] -= amount;
        bool ok = token.transfer(msg.sender, amount);
        require(ok, "TokenBankErc1363: transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    /// @notice token.transferAndCall(bank, amount[, data]) 转入后回调入账
    /// @dev 记到代币实际转出地址 `from` 名下
    function onTransferReceived(address, address from, uint value, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(token), "TokenBankErc1363: unknown token");
        require(value > 0, "TokenBankErc1363: zero deposit");
        deposits[from] += value;
        emit Deposit(from, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /// @notice token.approveAndCall(bank, amount[, data]) 授权后回调，Bank 再 pull 代币
    function onApprovalReceived(address owner, uint value, bytes calldata) external override returns (bytes4) {
        require(msg.sender == address(token), "TokenBankErc1363: unknown token");
        require(value > 0, "TokenBankErc1363: zero deposit");
        bool ok = token.transferFrom(owner, address(this), value);
        require(ok, "TokenBankErc1363: transferFrom failed");
        deposits[owner] += value;
        emit Deposit(owner, value);
        return IERC1363Spender.onApprovalReceived.selector;
    }
}
