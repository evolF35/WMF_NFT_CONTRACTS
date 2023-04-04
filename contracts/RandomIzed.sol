// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();

contract WMF_NFT4 is ERC721URIStorage,Ownable, VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_mintFee;
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;

    bool private s_initialized;

    mapping(uint256 => address) public s_requestIdToSender;

    event NftRequested(uint256 indexed requestId, address requester);

    constructor(        
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,

        string memory _name, 
        string memory _symbol, 
        address _owner) 

        VRFConsumerBaseV2(vrfCoordinatorV2)
        ERC721(_name, _symbol) 
        
        {

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;

        s_tokenCounter = 0;

        transferOwnership(_owner);
    }

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreETHSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    address musicOwner = s_requestIdToSender[requestId];
    uint256 newItemId = s_tokenCounter;
    s_tokenCounter = s_tokenCounter + 1;

    uint256 numCultures = 10; // Number of cultures in the Cultures enum
    uint256 numGenres = 5; // Number of genres in the Genres enum
    uint256 totalCombinations = numCultures * numGenres;

    uint256 moddedRng = randomWords[0] % totalCombinations;
    (Cultures culture, Genres genre) = getCultureAndGenreFromModdedRng(moddedRng);

    _safeMint(musicOwner, newItemId);
    _setTokenURI(newItemId, s_TokenUris[moddedRng]);

    tokenMetadata[newItemId] = TokenMetadata(culture, genre, false);
}

    function getCultureAndGenreFromModdedRng(uint256 moddedRng) public pure returns (Cultures, Genres) {
        uint256 numCultures = 10; // Number of cultures in the Cultures enum
        uint256 numGenres = 5; // Number of genres in the Genres enum
    
        uint256 totalCombinations = numCultures * numGenres;
        require(moddedRng < totalCombinations, "RandomIpfsNft__RangeOutOfBounds");
    
        uint256 cultureIndex = moddedRng / numGenres;
        uint256 genreIndex = moddedRng % numGenres;
    
        return (Cultures(cultureIndex), Genres(genreIndex));
}

    string[50] internal s_TokenUris;

function setTokenUris(string[50] calldata tokenUris) external onlyOwner {
    require(!s_initialized, "RandomIpfsNft__AlreadyInitialized");
    require(tokenUris.length == 50, "RandomIpfsNft__InvalidUriCount");

    // Copy elements from the calldata array to the storage array
    for (uint256 i = 0; i < tokenUris.length; ++i) {
        s_TokenUris[i] = tokenUris[i];
    }
    s_initialized = true;
}


    function _initializeContract() public onlyOwner {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_initialized = true;
    }



// --------------------------------------------------------------------------------

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getTokenUris(uint256 index) public view returns (string memory) {
        return s_TokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

//--------------------------------------------------------------------------------

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
        bool isFused;
    }

    mapping(uint256 => TokenMetadata) public tokenMetadata;
    
    function mint(
        address to, 
        uint256 tokenId,
        Cultures _culture,
        Genres _genre
                            ) public onlyOwner {
        require(
            !_exists(tokenId), "Token already minted");
        require(
            whitelistedAddresses[to], "Address not whitelisted");

        _safeMint(to, tokenId);
        tokenMetadata[tokenId] = TokenMetadata(_culture, _genre,false); // Set metadata directly
    }

    function burn(uint256 tokenId) public {
        require(
            _exists(tokenId), "Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender, "You are not the owner of this token");

        _burn(tokenId);
        delete tokenMetadata[tokenId]; // Delete metadata associated with the token
    }

    function fusion(uint256 tokenID1, uint256 tokenID2) public{
        require(
            _exists(tokenID1) && _exists(tokenID2), "One of the tokens does not exist");
        require(
            ownerOf(tokenID1) == msg.sender && ownerOf(tokenID2) == msg.sender, "You don't own both");
        require(
            !(tokenMetadata[tokenID1].culture == tokenMetadata[tokenID2].culture),
            "Cannot fuse tokens with the same culture");
        require(
            !_exists(tokenIDcalculator(tokenID1,tokenID2)),"Token already minted");
        require(
            !tokenMetadata[tokenID1].isFused && !tokenMetadata[tokenID2].isFused, "One of the tokens is already fused");

        uint256 newTokenID = tokenIDcalculator(tokenID1, tokenID2);
        tokenMetadata[tokenID1].isFused = true;
        tokenMetadata[tokenID2].isFused = true;

        _safeMint(msg.sender, newTokenID);

        tokenMetadata[newTokenID] = TokenMetadata({
            culture: Cultures((uint256(tokenMetadata[tokenID1].culture) + uint256(tokenMetadata[tokenID2].culture)) % 10),
            genre: Genres((uint256(tokenMetadata[tokenID1].genre) + uint256(tokenMetadata[tokenID2].genre)) % 5),
            isFused: true  // Set the isFused field to true, as this token is a result of fusion
        });
    }

    function tokenIDcalculator(uint256 tokenID1, uint256 tokenID2) public view returns (uint256) {
        // Extract the culture and genre indices of the two initial NFTs
        uint256 c1 = uint256(tokenMetadata[tokenID1].culture);
        uint256 g1 = uint256(tokenMetadata[tokenID1].genre);
        uint256 c2 = uint256(tokenMetadata[tokenID2].culture);
        uint256 g2 = uint256(tokenMetadata[tokenID2].genre);

        // Combine the culture and genre indices to create a unique token ID
        uint256 newTokenID = (c1 * 5 * 9 + g1 * 9 + c2 * 5 + g2) + 2251;

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
