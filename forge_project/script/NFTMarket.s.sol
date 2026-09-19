// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

import "./BaseScript.s.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {MyERC721} from "../src/MyERC721.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketScript is BaseScript {
    MyERC20 public token;
    MyERC721 public nft;
    NFTMarket public market;

    function run() public broadcaster {
        token = new MyERC20("Camp Token", "CAMP");
        nft = new MyERC721();
        market = new NFTMarket(token, nft);

        console.log("MyERC20 deployed on %s", address(token));
        console.log("MyERC721 deployed on %s", address(nft));
        console.log("NFTMarket deployed on %s", address(market));

        saveContract("MyERC20", address(token));
        saveContract("MyERC721", address(nft));
        saveContract("NFTMarket", address(market));
    }
}
