// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {MyERC721} from "../src/MyERC721.sol";

contract MyERC721Test is Test {
    MyERC721 public nft;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    string internal constant URI_1 = "ipfs://token-1";
    string internal constant URI_2 = "ipfs://token-2";

    function setUp() public {
        nft = new MyERC721();
    }

    function test_NameAndSymbol() public view {
        assertEq(nft.name(), unicode"集训营学员卡");
        assertEq(nft.symbol(), "CAMP");
    }

    function test_MintAssignsOwnerAndUri() public {
        vm.expectEmit(true, true, true, true, address(nft));
        emit IERC721.Transfer(address(0), alice, 1);

        uint256 tokenId = nft.mint(alice, URI_1);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.tokenURI(1), URI_1);
    }

    function test_MintIncrementsTokenIds() public {
        uint256 first = nft.mint(alice, URI_1);
        uint256 second = nft.mint(bob, URI_2);

        assertEq(first, 1);
        assertEq(second, 2);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.tokenURI(2), URI_2);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_RevertMintToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        nft.mint(address(0), URI_1);
    }

    function test_RevertTokenURIForNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        nft.tokenURI(1);
    }

    function test_TransferFrom() public {
        nft.mint(alice, URI_1);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);

        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.tokenURI(1), URI_1);
    }
}
