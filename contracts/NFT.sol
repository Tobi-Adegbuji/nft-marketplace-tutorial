//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    ///@title: NFT

    //Importing counter struct from Counters utility library
    using Counters for Counters.Counter;

    //An auto-increment field for each token.
    //Instance fields marked as private should start with an underscore by convention
    Counters.Counter private _tokenIds;

    //address of the NFT market place
    address marketplaceAddress;

    constructor(address _marketplaceAddress)
        ERC721("Non Fungible Tokens", "NFT")
    {
        marketplaceAddress = _marketplaceAddress;
    }

    /// @notice creating a new token
    /// @param tokenURI: the token URI
    function createToken(string memory tokenURI) public returns (uint256) {
        //Sets a new token ID for the token to be minted
        _tokenIds.increment();
        uint256 nftId = _tokenIds.current();
        //minting the token
        _mint(msg.sender, nftId);
        //setting the token uri 
        _setTokenURI(nftId, tokenURI); 

        //Allows marketplace to make transactions for nft owner
        setApprovalForAll(marketplaceAddress, true); 

        //Our front end will call this function and get the id of the token back using web3
        //return minted token id 
        return nftId; 
    }
}

/// @dev explain to dev your method
/// @param foo: descrition of foo
/// @notice if you dont want to use dev or param
