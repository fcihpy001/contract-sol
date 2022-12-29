// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Project.sol";
import "./MerkleProof.sol";

contract WhiteList is Project {
    mapping(address => bool) public isWhiteProject;

    mapping(address => bytes32) public whiteRoot;
    mapping(address => uint) public whiteTotal; // 白名单总个数
    mapping(address => uint) public whiteMaxBuy;

    mapping(address => uint) public whiteReserve; // 预留白名单投资池
    mapping(address => uint) public whiteHasInvest; // 白名单预留投资池消耗情况

    mapping(address => uint) public userResrve; // 普通用户投资池
    mapping(address => uint) public userHasInvest; // 普通用户预留投资池消耗情况

    mapping(address => uint) public deflation; // 通缩情况


    function setProjectWhite(
        address _project,
        bytes32 _root,
        uint _maxBuy,
        uint _totalUsers
    ) public onlyProjectOwner(_project) {
        // 不超过最大配额
        require(
            _totalUsers * _maxBuy <=
                investAmount[_project] - investToOwner[_project],
            "user could max buy overflow coin pool"
        );

        isProjectInit[_project] = true;
        whiteRoot[_project] = _root;
        whiteTotal[_project] = _totalUsers;
        whiteMaxBuy[_project] = _maxBuy;
        whiteReserve[_project] = _totalUsers * _maxBuy;
        userResrve[_project] = investAmount[_project] - _totalUsers * _maxBuy;
    }

    function isWhite(
        address _project,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(
            _proof, whiteRoot[_project],
             keccak256(abi.encodePacked(msg.sender))
        );
    }
}