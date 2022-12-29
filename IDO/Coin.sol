// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Coin is ERC20 {
    constructor(uint _total) ERC20("Fixed", "FIX") {
        _mint(msg.sender, _total);
    }
}