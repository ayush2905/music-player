//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//constructor expects name and symbol of token
contract MusicNFTMarketplace is ERC721("ShrodyBuck", "Shrody"), Ownable {
    //points to data where all the music data for nfts is located on IPFS
    string public baseURI =
        "https://bafybeidhjjbjonyqcahuzlpt7sznmh4xrlbspa3gstop5o47l6gsiaffee.ipfs.nftstorage.link/"; //nft uploaded on ipfs
    string public baseExtension = ".json"; //of metadata
    address public artist; //etheruem address
    uint256 public royaltyFee;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        uint256 price;
    }
    MarketItem[] public marketItems;

    event MarketItemBought(
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price
    );

    event MarketItemRelisted(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    //the deployer will be the initial seller of each nft and will have to pay royalty fee that is why it is marked payable
    constructor(
        uint256 _royaltyFee,
        address _artist,
        uint256[] memory _prices
    ) payable {
        require(
            _prices.length * _royaltyFee <= msg.value,
            "Deployer must pay royalty fee for each token listed on the marketplace"
        );
        royaltyFee = _royaltyFee;
        artist = _artist;
        for (uint8 i = 0; i < _prices.length; i++) {
            require(_prices[i] > 0, " Price must be greater than zero");
            _mint(address(this), i); //inherited from ERC721, address of the contract
            marketItems.push(MarketItem(i, payable(msg.sender), _prices[i])); //msg.sender -> deployer here
        }
    }

    //checks only the deployer can call this contract
    function updateRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        royaltyFee = _royaltyFee;
    }

    //creates the sale of a music nft listed on the marketplace
    //transfers ownership of the nft as well as funds between parties
    function buyToken(uint256 _tokenId) external payable {
        uint256 price = marketItems[_tokenId].price;
        address seller = marketItems[_tokenId].seller;
        require(
            msg.value == price,
            "Please send the asking price in order to complete the purchase"
        );
        marketItems[_tokenId].seller = payable(address(0)); //since the item is being bought it is no longer being sold
        _transfer(address(this), msg.sender, _tokenId); //why not seller address instead of (addreess(this))
        payable(artist).transfer(royaltyFee); //who is paying them
        payable(seller).transfer(msg.value); //why full value?

        emit MarketItemBought(_tokenId, seller, msg.sender, price);
    }

    //allows someone to resell their music nft
    //what is means to resell?
    function resellToken(uint256 _tokenId, uint256 _price) external payable {
        require(msg.value == royaltyFee, "Must pay royalty");
        require(_price > 0, "Price must be greater than zero");

        marketItems[_tokenId].price = _price;
        marketItems[_tokenId].seller = payable(msg.sender);

        _transfer(msg.sender, address(this), _tokenId);
        emit MarketItemRelisted(_tokenId, msg.sender, _price);
    }
}
