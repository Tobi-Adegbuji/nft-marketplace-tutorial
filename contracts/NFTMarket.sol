//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//prevents re-entrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsIds;
    //total number of items sold
    Counters.Counter private _itemsSold;

    //owner of the smart contract
    address payable owner;

    // users must pay to place their NFT on the marketplace
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //A way to access values of the MarketItem struct by passing an integer Id
    mapping(uint256 => MarketItem) private idMarketItem;

    //events are a way to log messages
    //We will use to log message when item is sold.
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /// @notice function to get listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /// @notice function to create market item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be above 0");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();

        idMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender), //Address of the seller placing the NFT for sale
            payable(address(0)), //no owner yet, so set to empty address
            price,
            false
        );

        //Transfer ownership of the NFT to the contract (marketplace) itself
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        //Logging transaction
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /// @notice function to create a sale
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idMarketItem[itemId].price;
        uint256 tokenId = idMarketItem[itemId].itemId;

        require(
            msg.value == price,
            "Must submit asking price in order to complete purchase"
        );

        //Pay the seller the amount
        idMarketItem[itemId].seller.transfer(msg.value);

        //Transfer ownership of the NFT from the owner to the buyer.
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            itemId
        );

        //mark buyer as new owner
        idMarketItem[itemId].owner = payable(msg.sender);

        //Mark has been sold
        idMarketItem[itemId].sold = true;

        //Increment the total number of items sold by one
        _itemsSold.increment();

        //Pay owner of contract the listing price
        payable(owner).transfer(listingPrice); 

    }


    /// @notice total number of items unsold on marketplace
    function getUnsoldMarketItems() public view returns (MarketItem[] memory){
        uint itemCount = _itemsIds.current(); //TOTAL number of items created on platform.
        uint unsoldItemCount = itemCount - _itemsSold.current(); //Unsold items on the platform
        uint currentIndex = 0; 

        MarketItem[] memory unsoldItems = new MarketItem[](unsoldItemCount); 

        for(uint i = 0; i < itemCount; i++){
            if(idMarketItem[i+1].owner == address(0)){
                uint currentId = idMarketItem[i + 1].itemId; 
                MarketItem storage currentItem = idMarketItem[currentId]; 
                unsoldItems[currentIndex] = currentItem; 
                currentIndex += 1; 
            }
        }

        return unsoldItems; 
    }

    //02:04:33
}
