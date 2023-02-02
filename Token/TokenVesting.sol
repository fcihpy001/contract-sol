// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20/ERC20.sol";

/**
 * @title ERC20代币线性释放
 * @dev 这个合约会将ERC20代币线性释放给给受益人`_beneficiary`。
 * 释放的代币可以是一种，也可以是多种。释放周期由起始时间`_start`和时长`_duration`定义。
 * 所有转到这个合约上的代币都会遵循同样的线性释放周期，并且需要受益人调用`release()`函数提取。
 * 合约是从OpenZeppelin的VestingWallet简化而来。
 * 
 * 线性释放指的是代币在归属期内匀速释放。举个例子，某私募持有365,000枚ICU代币，归属期为1年（365天），
 * 那么每天会释放1,000枚代币。
 */
contract TokenVesting {
    event ERC20Released(address indexed token, uint256 amount);

    mapping(address => uint256) public erc20Released;  //记录受益人已领取的代币数量
    address public immutable beneficiary;  // 受益人地址
    uint256 public immutable start;  // 归属期起始时间戳
    uint256 public immutable duration;  // 归属期 (秒)


    constructor(
        address _beneficiary,
        uint256 _duration
    ) {
        require(_beneficiary != address(0),  "VestingWallet: beneficiary is zero address");
        beneficiary = _beneficiary;
        start = block.timestamp;
        duration = _duration;
    }

    /**
     * @dev 受益人提取已释放的代币。
     * 调用vestedAmount()函数计算可提取的代币数量，然后transfer给受益人。
     * 释放 {ERC20Released} 事件.
     */
    function release(address token) public {
        // 计算可提取的代币数量
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // 更新已释放代币数量  
        erc20Released[token] += releasable;

        
        // 转代币给受益人
        IERC20(token).transfer(beneficiary, releasable);
        emit ERC20Released(token, releasable);
    }

    /**
     * @dev 根据线性释放公式，计算已经释放的数量。开发者可以通过修改这个函数，自定义释放方式。
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // 计算合约里总共收到了多少代币（当前余额 + 已经提取）
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];

        // 根据线性释放公式，计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }


    }

}