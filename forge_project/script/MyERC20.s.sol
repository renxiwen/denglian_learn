// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract MyERC20Script is Script {
    MyERC20 public token;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        token = new MyERC20("My Token", "MTK");

        vm.stopBroadcast();
    }
}
