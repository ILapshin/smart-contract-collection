// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftEnglishAuction__CallerIsNotOwnerOfNft();
error NftEnglishAuction__AlreadyStarted();
error NftEnglishAuction__NotStarted();
error NftEnglishAuction__ERC721NotApprovedForAuction();
error NftEnglishAuction__ERC20NotApprovedForAuction();
error NftEnglishAuction__ERC20InsufficientFundsAuction();
error NftEnglishAuction__InsufficientAmount();
error NftEnglishAuction__Closed();
error NftEnglishAuction__NotSeller();
error NftEnglishAuction__NotClosed();
error NftEnglishAuction__LastingNotElapsed();
error NftEnglishAuction__NothingToWithdraw();

/**
 * @dev Implementation of an NFT English Auction
 *
 * Payment is accepten in specified ERC20 token.
 *
 * This contract must be started by the seller after creation.
 *
 * This contract must obtain permission for ERC721 from a seller for starting the auction
 * and for ERC20 from bidders to make bids. Contract holds the NFT for selling and
 * payment tokens from bids. Lost bidders can withdraw their funds anytime.
 *
 * The seller must close the auction after lasting time is expired. If there were any bids,
 * NFT is transfered to the highest bidder and the amount of the highest bid is transfered to the seller.
 * Otherwise NFT is transferd back the the seller.
 */
contract NftEnglishAuction {
    event AuctionCreated(
        address seller,
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 startingPrice,
        uint256 lastingTime
    );

    event AuctionStarted(uint256 andsAt);

    event Bid(address bidder, uint256 amount);

    event AuctionClosed(address highestBidder, uint256 highestBid);

    event Withdrawal(address bidder, uint256 amount);

    IERC721 public immutable nft;
    uint256 public immutable tokenId;
    IERC20 public immutable paymentToken;
    address public immutable seller;
    uint256 public immutable lastingTime;

    uint256 public endsAt;
    bool public isStarted;
    bool public isClosed;

    address public highestBidder;
    uint256 public highestBid;

    // Mapping bidder address to his balance transfered to this contract
    mapping(address => uint256) private _balances;

    constructor(
        address _nftAddress,
        uint256 _tokenId,
        address _paymentTokenAddress,
        uint256 _lastingTime,
        uint256 _startingPrice
    ) {
        nft = IERC721(_nftAddress);
        if (nft.ownerOf(_tokenId) != msg.sender) {
            revert NftEnglishAuction__CallerIsNotOwnerOfNft();
        }
        tokenId = _tokenId;
        paymentToken = IERC20(_paymentTokenAddress);
        seller = msg.sender;
        highestBid = _startingPrice;
        lastingTime = _lastingTime;

        emit AuctionCreated(
            msg.sender,
            _nftAddress,
            _tokenId,
            _paymentTokenAddress,
            _startingPrice,
            lastingTime
        );
    }

    /**
     * @dev seller must approve the selling token of approve for all befor calling this function
     */
    function start() external {
        if (isStarted) {
            revert NftEnglishAuction__AlreadyStarted();
        }
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert NftEnglishAuction__ERC721NotApprovedForAuction();
        }
        isStarted = true;
        endsAt = block.timestamp + lastingTime;
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit AuctionStarted(endsAt);
    }

    /**
     * @dev bidder must approve payment token before calling this function
     */
    function bid(uint256 amount) external {
        if (!isStarted) {
            revert NftEnglishAuction__NotStarted();
        }

        if (block.timestamp >= endsAt) {
            revert NftEnglishAuction__Closed();
        }

        if (paymentToken.allowance(msg.sender, address(this)) < amount) {
            revert NftEnglishAuction__ERC20NotApprovedForAuction();
        }

        if (paymentToken.balanceOf(msg.sender) < amount) {
            revert NftEnglishAuction__ERC20InsufficientFundsAuction();
        }

        if (amount < highestBid) {
            revert NftEnglishAuction__InsufficientAmount();
        }

        if (highestBidder != address(0)) {
            _balances[highestBidder] = _balances[highestBidder] + highestBid;
        }

        highestBidder = msg.sender;
        highestBid = amount;

        paymentToken.transferFrom(msg.sender, address(this), amount);

        emit Bid(msg.sender, amount);
    }

    function closeAuction() external {
        if (msg.sender != seller) {
            revert NftEnglishAuction__NotSeller();
        }

        if (block.timestamp < endsAt) {
            revert NftEnglishAuction__LastingNotElapsed();
        }

        if (isClosed) {
            revert NftEnglishAuction__Closed();
        }

        isClosed = true;
        if (highestBidder == address(0)) {
            nft.transferFrom(address(this), seller, tokenId);
        } else {
            paymentToken.transfer(seller, highestBid);
            nft.transferFrom(address(this), highestBidder, tokenId);
        }

        emit AuctionClosed(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 amount = _balances[msg.sender];

        if (amount <= 0) {
            revert NftEnglishAuction__NothingToWithdraw();
        }

        _balances[msg.sender] = 0;
        paymentToken.transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address bidder) public view returns (uint256) {
        return _balances[bidder];
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= endsAt;
    }
}
