// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract WMF_NFT is ERC721URIStorage, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant COMBINE_ATTRIBUTE_INITIAL_VALUE = 100;
    string private baseURI;

    mapping (uint256 => bool) public burnedTokens;
    mapping (address => bool) public whitelistedAddresses;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintToken(address to, uint256 tokenId, string memory metadataHash) public onlyOwner {
    _mint(to, tokenId);
    _setTokenURI(tokenId, metadataHash);
    }

    function getCombinedAttribute(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return COMBINE_ATTRIBUTE_INITIAL_VALUE - (tokenId % COMBINE_ATTRIBUTE_INITIAL_VALUE);
    }




    function burnToken(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only the owner can burn the token");
        require(!burnedTokens[tokenId], "Token has already been burned");

        _burn(tokenId);
        burnedTokens[tokenId] = true;
    }
    function setWhitelistedAddress(address addr, bool status) public onlyOwner {
        whitelistedAddresses[addr] = status;
    }
    function isSaleOrTransferAllowed(address from, address to) internal view returns (bool) {
        return (whitelistedAddresses[from] && whitelistedAddresses[to]);
    }
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        super.safeTransferFrom(from, to, tokenId, _data);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        super.safeTransferFrom(from, to, tokenId);
    }

}
