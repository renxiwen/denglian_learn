// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {MyERC721} from "../src/MyERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    MyERC20 public token;
    MyERC721 public nft;

    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");

    uint256 internal constant PRICE = 100 ether;
    string internal constant URI = "ipfs://token-1";

    function setUp() public {
        token = new MyERC20("Camp Token", "CAMP");
        nft = new MyERC721();
        market = new NFTMarket(token, nft);

        token.transfer(buyer, PRICE * 2);
        nft.mint(seller, URI);
    }

    function test_ListAndBuyNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        vm.expectEmit(true, true, false, true, address(market));
        emit NFTMarket.Listed(seller, 1, PRICE);
        market.list(1, PRICE);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), address(market));
        (address listedSeller, uint256 listedPrice) = market.listings(1);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, PRICE);

        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        vm.expectEmit(true, true, true, true, address(market));
        emit NFTMarket.Bought(buyer, seller, 1, PRICE);
        market.buyNFT(1, PRICE);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(token.balanceOf(buyer), PRICE);
        (listedSeller, listedPrice) = market.listings(1);
        assertEq(listedSeller, address(0));
        assertEq(listedPrice, 0);
    }

    function test_BuyNFTAllowsOverpayButChargesListedPrice() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        uint256 overpay = PRICE + 10 ether;
        vm.startPrank(buyer);
        token.approve(address(market), overpay);
        market.buyNFT(1, overpay);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(token.balanceOf(buyer), PRICE);
    }

    function test_RevertListZeroPrice() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        vm.expectRevert("NFTMarket: zero price");
        market.list(1, 0);
        vm.stopPrank();
    }

    function test_RevertListNotOwner() public {
        vm.prank(buyer);
        vm.expectRevert("NFTMarket: not owner");
        market.list(1, PRICE);
    }

    function test_RevertBuyNotListed() public {
        vm.prank(buyer);
        vm.expectRevert("NFTMarket: not listed");
        market.buyNFT(1, PRICE);
    }

    function test_RevertBuyInsufficientPayment() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        vm.expectRevert("NFTMarket: insufficient payment");
        market.buyNFT(1, PRICE - 1);
        vm.stopPrank();
    }

    function test_RevertSelfBuy() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.expectRevert("NFTMarket: self buy");
        market.buyNFT(1, PRICE);
        vm.stopPrank();
    }

    function test_TokensReceivedBuysNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, true, address(market));
        emit NFTMarket.Bought(buyer, seller, 1, PRICE);
        token.transferWithCallback(address(market), PRICE, abi.encode(uint256(1)));
        vm.stopPrank();

        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(token.balanceOf(buyer), PRICE);
        assertEq(token.balanceOf(address(market)), 0);
        (address listedSeller, uint256 listedPrice) = market.listings(1);
        assertEq(listedSeller, address(0));
        assertEq(listedPrice, 0);
    }

    function test_TokensReceivedRefundsOverpay() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        uint256 overpay = PRICE + 10 ether;
        vm.prank(buyer);
        token.transferWithCallback(address(market), overpay, abi.encode(uint256(1)));

        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(token.balanceOf(buyer), PRICE * 2 - PRICE);
        assertEq(token.balanceOf(address(market)), 0);
    }

    function test_RevertTokensReceivedInsufficientPayment() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert("NFTMarket: insufficient payment");
        token.transferWithCallback(address(market), PRICE - 1, abi.encode(uint256(1)));
    }

    function test_RevertTokensReceivedUnknownToken() public {
        vm.prank(buyer);
        vm.expectRevert("NFTMarket: unknown token");
        market.tokensReceived(buyer, PRICE, abi.encode(uint256(1)));
    }

    function test_RevertTokensReceivedEmptyData() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(1, PRICE);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert("NFTMarket: empty data");
        token.transferWithCallback(address(market), PRICE, "");
    }
}
