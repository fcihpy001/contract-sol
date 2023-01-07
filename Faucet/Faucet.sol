

// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;
import "../Token/IERC20.sol";
contract Faucet {
    uint256 public amountAllowed = 100;
    address public tokenContract;

    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestToken() external {
        require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract);

        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); 
        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;

        emit SendToken(msg.sender, amountAllowed);
    }

}