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
        require(
            isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(
            isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(
            isSaleOrTransferAllowed(from, to), "Sale or transfer not allowed");
        
        super.safeTransferFrom(from, to, tokenId);
    }

    enum Cultures{
        African,
        North_American,
        South_American,
        Middle_Eastern,
        Asian,
        Western_European,
        Eastern_European,
        Oceanic,
        Caribbean,
        Antartic
    }

    enum Genres{
        Rock,
        Jazz,
        Hip_hop,
        Classical,
        Electronic
    }

    struct TokenMetadata {
        Cultures culture;
        Genres genre;
    }

    mapping(uint256 => TokenMetadata) public tokenMetadata;

    //1,125 combinations
    
    function mint(
        address to, 
        uint256 tokenId,
        Cultures _culture,
        Genres _genre
                            ) public {
        require(
            !_exists(tokenId), "Token already minted");
        require(
            whitelistedAddresses[to], "Address not whitelisted");

        _safeMint(to, tokenId);
        tokenMetadata[tokenId] = TokenMetadata(_culture, _genre); // Set metadata directly
    }

    function burn(uint256 tokenId) public {
        require(
            _exists(tokenId), "Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender, "You are not the owner of this token");

        _burn(tokenId);
        delete tokenMetadata[tokenId]; // Delete metadata associated with the token
    }

    function fusion(uint256 tokenID1, uint256 tokenID2, uint256 tokenID3) public{
        require(
            _exists(tokenID1) && _exists(tokenID2), "One of the tokens does not exist");
        require(
            ownerOf(tokenID1) == msg.sender && ownerOf(tokenID2) == msg.sender, "You don't own both");
        require(
            !(tokenMetadata[tokenID1].culture == tokenMetadata[tokenID2].culture),
            "Cannot fuse tokens with the same culture");

        uint256 newTokenID = tokenIDcalculator(tokenID1, tokenID2);

        _safeMint(msg.sender, tokenID3);

        tokenMetadata[newTokenID] = TokenMetadata({
            culture: Cultures((uint256(tokenMetadata[tokenID1].culture) + uint256(tokenMetadata[tokenID2].culture)) % 10),
            genre: Genres((uint256(tokenMetadata[tokenID1].genre) + uint256(tokenMetadata[tokenID2].genre)) % 5)
        });
    }

    function tokenIDcalculator(uint256 tokenID1, uint256 tokenID2) public view returns (uint256) {
        // Extract the culture and genre indices of the two initial NFTs
        uint256 c1 = uint256(tokenMetadata[tokenID1].culture);
        uint256 g1 = uint256(tokenMetadata[tokenID1].genre);
        uint256 c2 = uint256(tokenMetadata[tokenID2].culture);
        uint256 g2 = uint256(tokenMetadata[tokenID2].genre);

        // Combine the culture and genre indices to create a unique token ID
        uint256 newTokenID = (c1 * 1000) + (g1 * 100) + (c2 * 10) + g2;

        return newTokenID;
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(
            block.timestamp < 7991303455, "Too late to change base URI");
        
        _baseTokenURI = baseURI;
    }
}


// 3,375 total NFTs
// 2,250 initial NFTs
// 1,125 combinations


// 1,125 combinations
    // 
