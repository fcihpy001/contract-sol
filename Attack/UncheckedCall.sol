// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

contract UncheckedBank {

    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }
    function widthdraw() external {
        uint256 balance = balanceOf[msg.sender];

        require(balance > 0, "Insufficient balancee");
        balanceOf[msg.sender] = 0;
        bool success = payable(msg.sender).send(balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    UncheckedBank public bank;

    constructor(UncheckedBank _bank) {
        bank = _bank;
    }

    receive() external payable {
        revert();
    }

    // 存款函数，调用时msg.value 设为存款数量
    function deposit() external payable {
        bank.deposit{
            value:msg.value
        }();
    }

    // 取款函数，虽然调用成功，蛤实际上取款失败
    function withdraw() external payable {
        bank.widthdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}