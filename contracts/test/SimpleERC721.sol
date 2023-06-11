// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleERC721 is ERC721 {
    uint256 private _amountToken;
    string private constant _tokenURI =
        "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/0";

    constructor(address[] memory minters) ERC721("Simple ERC721", "TEST") {
        for (uint256 i = 0; i < minters.length; i++) {
            _safeMint(minters[i], _amountToken);
            _amountToken = _amountToken + 1;
        }
    }

    function mint() external {
        _safeMint(msg.sender, _amountToken);
        _amountToken = _amountToken + 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return _tokenURI;
    }
}
