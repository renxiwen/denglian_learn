// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721 is ERC721URIStorage {
    uint256 private _nextTokenId;

    constructor() ERC721(unicode"集训营学员卡", "CAMP") {}

    function mint(address to, string memory uri) public returns (uint256) {
        uint256 newItemId = ++_nextTokenId;
        _mint(to, newItemId);
        _setTokenURI(newItemId, uri);
        return newItemId;
    }
}
