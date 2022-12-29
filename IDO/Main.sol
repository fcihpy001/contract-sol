// SPDX-License-Identifier: MIT
/*
 * 术语约束
 * project 为分红代币，即项目方代币
 * invest 为流动性代币，即USDT，BNB等
 */
pragma solidity ^0.8.0;

import "./User.sol";

contract Main is User {

    // 待领取收益 = ((当前时间-项目结束时间) / (延迟释放时间)) * 总收益 - 已领取收益。
    function userCanWithdraw(address _project) public view returns (uint) {
        if (endTime[_project] > block.timestamp) {
            return 0;
        }

        if (freeLineTime[_project] == 0 || 
            block.timestamp - endTime[_project] >= freeLineTime[_project] ) {
             return userInvests[msg.sender][_project].reward - userInvests[msg.sender][_project].hasReward;
        } else {
            return
                (((block.timestamp - endTime[_project]) *
                    userInvests[msg.sender][_project].reward) /
                    freeLineTime[_project]) -
                userInvests[msg.sender][_project].hasReward;
        }
   
    }
    /** 用户提款
     * 1.先计算用户能提多少钱
     * 2.修改用户与项目相关的数据
     * 3.执行提款操作
     */
    function userWithdraw(address _project) public returns (bool) {
        uint canWithdrew = userCanWithdraw(_project);
        userInvests[msg.sender][_project].hasReward += canWithdrew;
        return IERC20(_project).transfer(msg.sender, canWithdrew);
    }

    /**
     * 项目方提款
     * 
     */
    function projectWithdraw(address _project) 
        public onlyProjectOwner(_project) returns (bool) {
        // 仅在项目结束后提款
        require(endTime[_project] < block.timestamp);

        // TODO: 仅项目方地址可以提款
        require(_project == msg.sender);

        uint investCanWithdraw = investToOwner[_project];
        uint projectCanWithdraw = projectPoolTotal[_project];

        // 收益和代币清零
        investToOwner[_project] = 0; // 项目收益清零
        projectPoolTotal[_project] = 0; // 项目代币清零

        // 向合约调用者账户打款
        IERC20(invest[_project]).transfer(msg.sender, investCanWithdraw);
        IERC20(_project).transfer(msg.sender, projectCanWithdraw);
        return true;
    }

    fallback() external payable {}

    receive() external payable {}
}