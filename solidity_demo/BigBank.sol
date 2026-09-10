// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Bank.sol";

contract BigBank is Bank {
    modifier minDeposit() {
        require(msg.value > 0.001 ether, "deposit must > 0.001 ether");
        _;
    }

    receive() external payable override minDeposit {
        _deposit(msg.sender, msg.value);
    }

    function deposit() external payable override minDeposit {
        _deposit(msg.sender, msg.value);
    }
}

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    receive() external payable {}

    /// @notice 只有本合约（作为 BigBank.admin）能调用 BigBank.withdraw()
    function withdraw(BigBank bank) external onlyOwner {
        bank.withdraw();
    }

    function withdrawToOwner() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "no balance");
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }
}
