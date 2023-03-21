// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract WMF_NFT is ERC721URIStorage,Ownable {

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _owner) ERC721(_name, _symbol) {
        transferOwnership(_owner);
    }

    mapping (address => bool) public whitelistedAddresses;

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

    enum Cultures{
        African,
        North_American,
        South_American,
        Middle_Eastern,
        Asian,
        European,
        Oceanic
    }

    enum Genres{
        Rock,
        Jazz,
        Hip_hop,
        Classical,
        Pop,
        Country,
        Electronic,
        Reggae,
        Blues,
        Heavy_Metal
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }



}