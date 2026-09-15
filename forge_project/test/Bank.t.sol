// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");

    function setUp() public {
        bank = new Bank();
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
    }

    function _deposit(address user, uint amount) internal {
        vm.prank(user);
        bank.deposit{value: amount}();
    }

    function _assertTop3(address a, address b, address c) internal view {
        (address[3] memory users, uint[3] memory amounts) = bank.getTop3();
        assertEq(users[0], a, "top1 user mismatch");
        assertEq(users[1], b, "top2 user mismatch");
        assertEq(users[2], c, "top3 user mismatch");
        assertEq(amounts[0], a == address(0) ? 0 : bank.balances(a), "top1 amount mismatch");
        assertEq(amounts[1], b == address(0) ? 0 : bank.balances(b), "top2 amount mismatch");
        assertEq(amounts[2], c == address(0) ? 0 : bank.balances(c), "top3 amount mismatch");
    }

    function test_DepositUpdatesUserBalance() public {
        assertEq(bank.balances(user1), 0);

        uint first = 1 ether;
        uint beforeBal = bank.balances(user1);
        _deposit(user1, first);
        assertEq(bank.balances(user1), beforeBal + first);

        uint second = 2.5 ether;
        beforeBal = bank.balances(user1);
        _deposit(user1, second);
        assertEq(bank.balances(user1), beforeBal + second);
        assertEq(bank.balances(user1), 3.5 ether);
    }

    function test_DepositViaReceiveUpdatesBalance() public {
        assertEq(bank.balances(user1), 0);

        vm.prank(user1);
        (bool ok,) = address(bank).call{value: 3 ether}("");
        assertTrue(ok);
        assertEq(bank.balances(user1), 3 ether);
    }

    function test_Top3WithOneUser() public {
        _deposit(user1, 1 ether);

        _assertTop3(user1, address(0), address(0));
        assertEq(bank.balances(user1), 1 ether);
    }

    function test_Top3WithTwoUsers() public {
        _deposit(user1, 1 ether);
        _deposit(user2, 3 ether);

        _assertTop3(user2, user1, address(0));
        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.balances(user2), 3 ether);
    }

    function test_Top3WithThreeUsers() public {
        _deposit(user1, 1 ether);
        _deposit(user2, 5 ether);
        _deposit(user3, 3 ether);

        _assertTop3(user2, user3, user1);
        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.balances(user2), 5 ether);
        assertEq(bank.balances(user3), 3 ether);
    }

    function test_Top3WithFourUsersKeepsHighestThree() public {
        _deposit(user1, 1 ether);
        _deposit(user2, 5 ether);
        _deposit(user3, 3 ether);
        _deposit(user4, 4 ether);

        _assertTop3(user2, user4, user3);
        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.balances(user4), 4 ether);
        assertTrue(bank.top3(0) != user1);
        assertTrue(bank.top3(1) != user1);
        assertTrue(bank.top3(2) != user1);
    }

    function test_Top3FourthUserDoesNotEnterIfSmaller() public {
        _deposit(user1, 10 ether);
        _deposit(user2, 8 ether);
        _deposit(user3, 6 ether);
        _deposit(user4, 1 ether);

        _assertTop3(user1, user2, user3);
        assertEq(bank.balances(user4), 1 ether);
    }

    function test_SameUserMultipleDepositsUpdatesRank() public {
        _deposit(user1, 1 ether);
        _deposit(user2, 4 ether);
        _deposit(user3, 3 ether);

        _assertTop3(user2, user3, user1);

        uint before = bank.balances(user1);
        _deposit(user1, 5 ether);
        assertEq(bank.balances(user1), before + 5 ether);
        assertEq(bank.balances(user1), 6 ether);

        _assertTop3(user1, user2, user3);
    }

    function test_SameUserMultipleDepositsStaysInTop3WithoutDuplicating() public {
        _deposit(user1, 2 ether);
        _deposit(user1, 3 ether);
        _deposit(user2, 1 ether);

        _assertTop3(user1, user2, address(0));
        assertEq(bank.balances(user1), 5 ether);

        (address[3] memory users,) = bank.getTop3();
        uint appearances;
        for (uint i = 0; i < 3; i++) {
            if (users[i] == user1) appearances++;
        }
        assertEq(appearances, 1);
    }
}
