# Solidity Smart Contract Collection

A collection of various Solidity smart contracts.

## NFT Trading

Smart contracts that allows to trade ERC721 in various ways. The main difference from common contracts of the same functionality is that payment oparations are held in ERC20 tokens instead of native ETH currency.

### NftMarketplace

Implementation of simple NFT Marketplace. Payments proceed in ERC20 token specified while contact creation. This contract does not hold any tokens of users, neither ERC721 NFT, nor ERC20 payment token, instead it plays as a mediator.

## Test

This section contains utility contracts for testing:

- ERC20 token that allows to mint an amount of tokens to any address.
- ERC721 NFT that allows to mint a token with yet another token id. It also has a fixed sample URI metadata.
