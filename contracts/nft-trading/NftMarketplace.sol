// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__NotOwner();
error NftMarketplace__AlreadyListed();
error NftMarketplace__NotListed();
error NftMarketplace__ZeroPrice();
error NftMarketplace__ERC721NotApprovedForMarketplace();
error NftMarketplace__ERC20NotApprovedForMarketplace();
error NftMarketplace__ERC20InsufficientBalance();

/**
 * @dev Implementation of simple NFT Marketplace
 *
 * The main difference from same common smart contracts is that payment
 * is accepten not in ETH, but in specified ERC20 token.
 *
 * This contract does not hold any tokens of users, it plays as a mediator.
 *
 * This contract must obtain permission for ERC721 and ERC20
 * from a seller and from a buyer respectively for execution of listing and buying.
 */
contract NftMarketplace {
    // Listing of an exect NFT containing info about seller and selling price
    struct Listing {
        address seller;
        uint256 price;
    }

    event ItemListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event ItemSold(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );

    event ItemCanceled(address indexed nftAddress, uint256 indexed tokenId);

    // ERC20 token wchich is accepted as a payment
    IERC20 private immutable _paymentToken;

    // Mapping NFT Contract Address => NFT Token ID => Listing
    mapping(address => mapping(uint256 => Listing)) private _listings;

    /**
     * @dev paymentToken should be verified by the contract creator to be a valid ERC20 token
     * and not to contain any logic that can implement reentrancy attack.
     */
    constructor(address paymentTokenAddress) {
        _paymentToken = IERC20(paymentTokenAddress);
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = _listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed();
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = _listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListed();
        }
        _;
    }

    /**
     * @dev User must grand permission for transfering the token to this contract before listing.
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        notListed(nftAddress, tokenId)
    {
        if (price <= 0) {
            revert NftMarketplace__ZeroPrice();
        }
        IERC721 nft = IERC721(nftAddress);
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert NftMarketplace__ERC721NotApprovedForMarketplace();
        }
        _listings[nftAddress][tokenId] = Listing(msg.sender, price);
        emit ItemListed(nftAddress, tokenId, msg.sender, price);
    }

    /**
     * @dev Reentrancy defence is not applied in this implementation
     * since the payment ERC20 token is being setting by a contact creator
     * who should check it doesn't contain any malicious logic.
     */
    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external isListed(nftAddress, tokenId) {
        Listing memory listing = _listings[nftAddress][tokenId];

        if (
            _paymentToken.allowance(msg.sender, address(this)) < listing.price
        ) {
            revert NftMarketplace__ERC20NotApprovedForMarketplace();
        }

        if (_paymentToken.balanceOf(msg.sender) < listing.price) {
            revert NftMarketplace__ERC20InsufficientBalance();
        }

        IERC721 nft = IERC721(nftAddress);
        delete (_listings[nftAddress][tokenId]);
        _paymentToken.transferFrom(msg.sender, listing.seller, listing.price);
        nft.safeTransferFrom(listing.seller, msg.sender, tokenId);
        emit ItemSold(nftAddress, tokenId, msg.sender, listing.price);
    }

    function updateItem(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        _listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(nftAddress, tokenId, msg.sender, newPrice);
    }

    function cancelItem(
        address nftAddress,
        uint256 tokenId
    )
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        delete (_listings[nftAddress][tokenId]);
        emit ItemCanceled(nftAddress, tokenId);
    }

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) public view returns (Listing memory) {
        return _listings[nftAddress][tokenId];
    }

    function paymentToken() public view returns (address) {
        return address(_paymentToken);
    }
}
