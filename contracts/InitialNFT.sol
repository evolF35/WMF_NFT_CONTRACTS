// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();

contract WMF_NFT is ERC721URIStorage,VRFConsumerBaseV2 ,Ownable {

    enum Genre {
        Pop,
        Rock,
        Hip_hop,
        Country,
        R_and_B,
        Jazz,
        Blues,
        Electronic,
        techno, 
        house, 
        trance,
        Classical,
        Folk,
        World,
        African, 
        Latin, 
        Indian,
        Reggae,
        Metal,  
        heavy_metal, 
        thrash_metal, 
        black_metal,
        Punk,
        pop_punk, 
        hardcore_punk, 
        post_punk,
        Soul,
        Funk,
        Gospel,
        Opera,
        Broadway,
        West_End,
        Ambient,
        New_Age,
        Experimental,
        Alternative, 
        indie_rock,
        Grunge,
        Ska,
        Dubstep,
        Trap,
        Kpop,
        Jpop,
        Cpop
    }

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
    event NftMinted(Genre genre, address minter);

    string[] internal genre_URIS;

    uint256 private constant NUM_TYPE_MUSIC_GENRES = 20;
    uint256 private constant MAX_CROSS_GENRES = 400;
    uint256 private constant MAX_GENRES = 600;
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public numGenresMinted;
    uint256 public numCrossGenresMinted;
    string private baseURI;

    mapping (uint256 => bool) public burnedTokens;
    mapping (address => bool) public whitelistedAddresses;
    mapping (uint256 => bool) public mintedGenres;
    mapping (uint256 => bool) public mintedCrossGenres;

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, 
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[44] memory genreURIS,
        string memory _name, 
        string memory _symbol, 
        address _owner) 
    VRFConsumerBaseV2(vrfCoordinatorV2) ERC721(_name, _symbol) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;
        _initializeContract(genreURIS);
        s_tokenCounter = 0;
        transferOwnership(_owner);
    }

    function _initializeContract(string[44] memory genreURIS) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        genre_URIS = genreURIS;
        s_initialized = true;
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
        address consumer = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Genre genre = getGenreFromModdedRng(moddedRng);
        _safeMint(consumer, newItemId);
        _setTokenURI(newItemId, genre_URIS[uint256(genre)]);
        emit NftMinted(genre, consumer);
    }

    function getChanceArray() public pure returns (uint256[44] memory) {
    uint256[44] memory chanceArray;
    uint8[44] memory tempArray = [  1,1,1,1,1,1,1,
                                    1,1,1,1,1,1,1,
                                    1,1,1,1,1,1,1,
                                    1,1,1,1,1,1,1,
                                    1,1,1,1,1,1,1,
                                    1,1,1,1,1,1,1,
                                    1,1];

    for (uint256 i = 0; i < 44; i++) {
        chanceArray[i] = tempArray[i];
    }
    return chanceArray;
    }

    function getGenreFromModdedRng(uint256 moddedRng) public pure returns (Genre) {
        uint256 cumulativeSum = 0;
        uint256[44] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Genre(i);
            }
            cumulativeSum = chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

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
        mintedGenres[tokenId] = true; 
        numGenresMinted++;
    }

    function mintCrossGenre(uint256 genreTokenId1, uint256 genreTokenId2) public onlyOwner {
        require(genreTokenId1 > 0 && genreTokenId1 <= MAX_GENRES, "Invalid genre token ID");
        require(genreTokenId2 > 0 && genreTokenId2 <= MAX_GENRES, "Invalid genre token ID");
        require(genreTokenId1 != genreTokenId2, "Cannot burn two of the same genre");

        // Check that both genre NFTs have been minted
        require(mintedGenres[genreTokenId1] == true, "Genre NFT has not been minted yet");
        require(mintedGenres[genreTokenId2] == true, "Genre NFT has not been minted yet");

        // Burn the two genre NFTs
        _burn(genreTokenId1);
        _burn(genreTokenId2);

        // Mint the cross-genre NFT
        uint256 crossGenreTokenId = MAX_GENRES + numCrossGenresMinted + 1;
        _safeMint(msg.sender, crossGenreTokenId);
        mintedCrossGenres[crossGenreTokenId] = true;

        numCrossGenresMinted++;
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
