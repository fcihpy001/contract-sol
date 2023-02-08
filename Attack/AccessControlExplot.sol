// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 权限管理错误例子
contract AccessControlExploit is ERC20, Ownable {
    constructor() ERC20("Wrong Access", "WA") {}

    function bandMint(address to, uint amount) public {
        _mint(to, amount);
    }

    function goodMint(address to, uint256) public onlyOwner {
        _mint(to, amount);
    }

    function bandBurn(address account, uint amount) public {
        _burn(account, amount);
    }

    function goodBurn(address account, uint amount) public {
        if (msg.sender != account) {
            _spendAllownance(account, msg.sender, amount);
        }
        _burn(account, amount);
    }

}