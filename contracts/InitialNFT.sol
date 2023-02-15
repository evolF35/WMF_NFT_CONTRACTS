// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract WMF_NFT is ERC721URIStorage, Ownable {

    uint256 private constant NUM_TYPE_MUSIC_GENRES = 20;
    uint256 private constant MAX_CROSS_GENRES = 400;
    uint256 private constant MAX_GENRES = 600;
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public numGenresMinted;
    string private baseURI;

    mapping (uint256 => bool) public burnedTokens;
    mapping (address => bool) public whitelistedAddresses;
    mapping (uint256 => bool) public mintedGenres;


    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function mintGenre() public payable {
        require(numGenresMinted < MAX_GENRES, "All tokens have been minted");
        uint256 tokenId = numGenresMinted + 1;
        _safeMint(msg.sender, tokenId);
        mintedGenres[tokenId] = true; // add this line to update the mintedGenres mapping
        numGenresMinted++;
    }

    function mintCrossGenre(uint256 genreTokenId1, uint256 genreTokenId2) public payable {
        require(genreTokenId1 > 0 && genreTokenId1 <= numGenresMinted, "Invalid genre token ID");
        require(genreTokenId2 > 0 && genreTokenId2 <= numGenresMinted, "Invalid genre token ID");
        require(genreTokenId1 != genreTokenId2, "Cannot burn two of the same genre");

        // Check that both genre NFTs have been minted
        require(mintedGenres[genreTokenId1] == true, "Genre NFT has not been minted yet");
        require(mintedGenres[genreTokenId2] == true, "Genre NFT has not been minted yet");

        // Burn the two genre NFTs
        _burn(genreTokenId1);
        _burn(genreTokenId2);

        // Mint the cross-genre NFT
        uint256 tokenId = numGenresMinted + 1;
        _safeMint(msg.sender, tokenId);
        numGenresMinted++;
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
