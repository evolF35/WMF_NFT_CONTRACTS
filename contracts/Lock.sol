
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WMF is ERC721 {


    constructor() ERC721("WMF", "WMF") {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.wmf.art/api/v1/nft/";
    }
    
    
}
