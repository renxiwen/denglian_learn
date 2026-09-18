// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ITokenReceiver} from "./ITokenReceiver.sol";

contract MyERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    /// @notice 带额外数据的转账：若收款方为合约，则调用 tokensReceived。
    function transferWithCallback(address to, uint256 amount, bytes calldata data) external returns (bool) {
        _transfer(msg.sender, to, amount);
        if (to.code.length > 0) {
            ITokenReceiver(to).tokensReceived(msg.sender, amount, data);
        }
        return true;
    }
}
