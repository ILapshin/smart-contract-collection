// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleERC20 is ERC20 {
    uint256 public constant MINT_AMOUNT = 100000000000000000000;

    constructor(address[] memory minters) ERC20("Simple ERC20", "TEST") {
        for (uint256 i = 0; i < minters.length; i++) {
            _mint(minters[i], MINT_AMOUNT);
        }
    }

    function mint() external {
        _mint(msg.sender, MINT_AMOUNT);
    }
}
