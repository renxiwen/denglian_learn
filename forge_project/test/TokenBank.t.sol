// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract TokenBankLocalTest is Test {
    TokenBank public bank;
    MyERC20 public token;
    address public user = makeAddr("user");

    uint256 internal constant AMOUNT = 100 ether;

    function setUp() public {
        token = new MyERC20("Mock", "MOCK");
        bank = new TokenBank(token);
        token.transfer(user, AMOUNT);
    }

    function test_DepositAndWithdrawLocalErc20() public {
        vm.startPrank(user);
        token.approve(address(bank), AMOUNT);
        bank.deposit(AMOUNT);
        vm.stopPrank();

        assertEq(bank.deposits(user), AMOUNT);
        assertEq(token.balanceOf(address(bank)), AMOUNT);

        vm.prank(user);
        bank.withdraw(AMOUNT);

        assertEq(bank.deposits(user), 0);
        assertEq(token.balanceOf(user), AMOUNT);
    }

    function test_RevertZeroDeposit() public {
        vm.prank(user);
        vm.expectRevert("TokenBank: zero deposit");
        bank.deposit(0);
    }

    function test_RevertWithdrawMoreThanDeposit() public {
        vm.prank(user);
        vm.expectRevert("TokenBank: insufficient deposit");
        bank.withdraw(1);
    }
}

/// @dev 以太坊主网 fork：验证 TokenBank 能存取真实 USDT（无 bool 返回值）
contract TokenBankUsdtMainnetForkTest is Test {
    using SafeERC20 for IERC20;

    IERC20 internal constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    TokenBank internal bank;
    address internal user = makeAddr("usdtUser");
    uint256 internal constant AMOUNT = 1_000 * 1e6; // USDT 6 decimals

    function setUp() public {
        vm.createSelectFork("mainnet");
        bank = new TokenBank(USDT);
        deal(address(USDT), user, AMOUNT);
        assertEq(USDT.balanceOf(user), AMOUNT, "deal USDT failed");
    }

    function test_DepositAndWithdrawMainnetUsdt() public {
        uint256 userBefore = USDT.balanceOf(user);

        vm.startPrank(user);
        USDT.forceApprove(address(bank), AMOUNT);
        vm.expectEmit(true, false, false, true, address(bank));
        emit TokenBank.Deposit(user, AMOUNT);
        bank.deposit(AMOUNT);
        vm.stopPrank();

        assertEq(bank.deposits(user), AMOUNT);
        assertEq(USDT.balanceOf(address(bank)), AMOUNT);
        assertEq(USDT.balanceOf(user), userBefore - AMOUNT);

        vm.startPrank(user);
        vm.expectEmit(true, false, false, true, address(bank));
        emit TokenBank.Withdraw(user, AMOUNT);
        bank.withdraw(AMOUNT);
        vm.stopPrank();

        assertEq(bank.deposits(user), 0);
        assertEq(USDT.balanceOf(address(bank)), 0);
        assertEq(USDT.balanceOf(user), userBefore);
    }

    function test_PartialWithdrawMainnetUsdt() public {
        uint256 half = AMOUNT / 2;

        vm.startPrank(user);
        USDT.forceApprove(address(bank), AMOUNT);
        bank.deposit(AMOUNT);
        bank.withdraw(half);
        vm.stopPrank();

        assertEq(bank.deposits(user), half);
        assertEq(USDT.balanceOf(address(bank)), half);
        assertEq(USDT.balanceOf(user), half);
    }
}
