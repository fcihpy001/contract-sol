// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WhiteList.sol";

contract User is WhiteList {
    struct UserStruct {
        address project;
        address invest;
        address user;
        uint investTotal; //投资总额
        uint reward; //总奖励
        uint hasReward;  //已获奖励
    }
    // 用户投资项目情况
    mapping(address => mapping(address => UserStruct)) public userInvests;

    function intiWhiteInvest(
        address project,
        address invest,
        uint investTotal,
        bytes32[] memory _proof
    ) public {
         uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvests[msg.sender][project];

        bool userIsWhite = isWhite(project, _proof);

        require(userIsWhite, "you are not menbers of whitelists");

        // 限制池子必须有足够项目方代币
        require(
            whiteReserve[project] - whiteHasInvest[project] >= investTotal,
            "not enough project token"
        );

        // 限制单个用户投资配额
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal <= whiteMaxBuy[project],
            "invest buy range overflow"
        );

        // 限制仅可在项目运行周期内投资
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        /* 投入代币 */
        bool isInverstSuccess = IERC20(invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );

        /* 投入成功 */
        if (isInverstSuccess) {
            _initUserBaseConfig(project, invest);
            userInvests[msg.sender][project].investTotal = userInvestTotal; // 用户投资总额
            userInvests[msg.sender][project].reward =
                (ratio[project] * userInvestTotal) /
                10**18; // 用户的总收益
            investToOwner[project] += investTotal; // 项目方可收到的货款
            projectPoolTotal[project] -= (investTotal * ratio[project]) / 10**18; // 预支池子里的项目方代币
            whiteHasInvest[project] += investTotal; // 更新白名单预留池
        }
    }

    function initUserInvest(
        address project,
        address invest,
        uint investTotal
    ) public {
        uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvests[msg.sender][project];
        
        // 确保池子中有项目方足够的代币
        if (isWhiteProject[project]) {
            require(
                userResrve[project] - userHasInvest[project] >= investTotal,
                "not enough project token"
            );
        } else {
            require(
                projectPoolTotal[project] - (investTotal * ratio[project]) / 10**18 >= 0,
                "not enough project token"
            );
        }
        // 限制每个用用户的投资总额
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal >= investBuyMin[project] &&
                userInvestTotal <= investBuyMax[project],
            "invest buy range overflow"
        );

        // 确保投资发生在项目活动期内
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        // 投入代币
        bool isInvesrstSuccess = IERC20(invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );
        // 投资成功的逻辑
        if (isInvesrstSuccess) {
            _initUserBaseConfig(project, invest);
            // 更新用户投资总额
            userInvests[msg.sender][project].investTotal = userInvestTotal;
            // 计算用户收益
            userInvests[msg.sender][project].reward =   (ratio[project] * userInvestTotal) / 10**18;
            // 项目方收到的货款
            investToOwner[project] += investTotal;
            // 更新项目方池子中的代币
            projectPoolTotal[project] -= (investTotal * ratio[project]) / 10**18; 
            // 更新普通人的预留池
            userHasInvest[project] += investTotal; 

        }
    }

    function _initUserBaseConfig(address project, address invest) private {
        userInvests[msg.sender][project].project = project;
        userInvests[msg.sender][project].invest = invest;
        userInvests[msg.sender][project].user = msg.sender;
    }

}