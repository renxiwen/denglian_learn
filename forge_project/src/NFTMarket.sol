// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ITokenReceiver} from "./ITokenReceiver.sol";

/// @title NFTMarket
/// @notice 使用 MyERC20 购买 MyERC721。上架时将 NFT 托管到本合约。
contract NFTMarket is IERC721Receiver, ITokenReceiver {
    using SafeERC20 for IERC20;

    struct Listing {
        address seller;
        uint256 price;
    }

    IERC20 public immutable paymentToken;
    IERC721 public immutable nft;

    mapping(uint256 tokenId => Listing) public listings;

    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event Bought(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 price);

    constructor(IERC20 _paymentToken, IERC721 _nft) {
        require(address(_paymentToken) != address(0), "NFTMarket: zero token");
        require(address(_nft) != address(0), "NFTMarket: zero nft");
        paymentToken = _paymentToken;
        nft = _nft;
    }

    /// @notice NFT 持有者上架，price 为购买所需 TOKEN 数量。调用前需 approve 本市场。
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "NFTMarket: zero price");
        require(nft.ownerOf(tokenId) == msg.sender, "NFTMarket: not owner");
        require(listings[tokenId].seller == address(0), "NFTMarket: already listed");

        listings[tokenId] = Listing({seller: msg.sender, price: price});
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit Listed(msg.sender, tokenId, price);
    }

    /// @notice 买家转入 TOKEN 并获得 NFT。amount 不得低于上架价格，实际按标价扣款。
    function buyNFT(uint256 tokenId, uint256 amount) external {
        Listing memory listing = _takeListing(tokenId, msg.sender, amount);

        paymentToken.safeTransferFrom(msg.sender, listing.seller, listing.price);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Bought(msg.sender, listing.seller, tokenId, listing.price);
    }

    /// @notice MyERC20.transferWithCallback 的接收回调。data 为 abi.encode(tokenId)。
    /// @dev TOKEN 已转入本合约；按标价打给卖家，多出的部分退回买家。
    function tokensReceived(address from, uint256 amount, bytes calldata data) external {
        require(msg.sender == address(paymentToken), "NFTMarket: unknown token");
        require(data.length > 0, "NFTMarket: empty data");

        uint256 tokenId = abi.decode(data, (uint256));
        Listing memory listing = _takeListing(tokenId, from, amount);

        paymentToken.safeTransfer(listing.seller, listing.price);
        if (amount > listing.price) {
            paymentToken.safeTransfer(from, amount - listing.price);
        }
        nft.safeTransferFrom(address(this), from, tokenId);

        emit Bought(from, listing.seller, tokenId, listing.price);
    }

    function _takeListing(uint256 tokenId, address buyer, uint256 amount) internal returns (Listing memory listing) {
        listing = listings[tokenId];
        require(listing.seller != address(0), "NFTMarket: not listed");
        require(buyer != listing.seller, "NFTMarket: self buy");
        require(amount >= listing.price, "NFTMarket: insufficient payment");
        delete listings[tokenId];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(nft), "NFTMarket: unknown nft");
        return IERC721Receiver.onERC721Received.selector;
    }
}
