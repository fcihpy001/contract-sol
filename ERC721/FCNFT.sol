// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract FCNFT is ERC721{
    uint public MAX_APES = 10000;

    constructor (
        string memory _name, 
        string memory _symbol) ERC721(_name, _symbol) {

    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address to, uint tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES,  "tokenId out of range");
        _mint(to, tokenId);
    }
}