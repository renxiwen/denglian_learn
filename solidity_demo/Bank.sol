// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
    address public admin;
    mapping(address => uint) public balances;
    address[3] public top3;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        _deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == admin, "only admin");
        uint amount = address(this).balance;
        require(amount > 0, "no balance");
        (bool ok, ) = payable(admin).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function getTop3() external view returns (address[3] memory, uint[3] memory) {
        uint[3] memory amounts;
        for (uint i = 0; i < 3; i++) {
            amounts[i] = balances[top3[i]];
        }
        return (top3, amounts);
    }

    function _deposit(address user, uint amount) internal {
        require(amount > 0, "zero deposit");
        balances[user] += amount;
        _updateTop3(user);
    }

    function _updateTop3(address user) internal {
        uint userBal = balances[user];

        for (uint i = 0; i < 3; i++) {
            if (top3[i] == user) {
                _sortTop3();
                return;
            }
        }

        for (uint i = 0; i < 3; i++) {
            if (top3[i] == address(0) || userBal > balances[top3[i]]) {
                for (uint j = 2; j > i; j--) {
                    top3[j] = top3[j - 1];
                }
                top3[i] = user;
                return;
            }
        }
    }

    function _sortTop3() internal {
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (balances[top3[j]] < balances[top3[j + 1]]) {
                    address tmp = top3[j];
                    top3[j] = top3[j + 1];
                    top3[j + 1] = tmp;
                }
            }
        }
    }
}
