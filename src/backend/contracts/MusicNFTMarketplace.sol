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
}
