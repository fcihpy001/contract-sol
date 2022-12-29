// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Project {
    address owner;
    // 交易手续费，为固定值
    uint public fee;
    // 交易手续费收取的代币
    address public feeToken;

    // 通缩费率
    mapping (address => uint) public deflationContract;
    mapping (address => uint) public deflationUser;
    // 项目方配置
    // 
    mapping (address=>bool) public isProjectInit;
    mapping (address => address) public project;
    mapping (address => address) public projectOwner;
    mapping (address => uint) public projectAmount;

    // 项目的活动开始时间、结束时间 、线性释放时间
    mapping (address => uint) public startTime;
    mapping (address => uint) public endTime;
    mapping (address => uint) public freeLineTime;

    // 投资方配置
    mapping (address => address) public invest;
    mapping (address => uint) public investBuyMax;
    mapping (address => uint) public investBuyMin;
    mapping (address => uint) public investAmount;

    // 参与项目的投资总额
    mapping (address => uint) public investToOwner;
    // 项目池子总额
    mapping (address => uint) public projectPoolTotal;
    // 代币的转换利率， 100 000为100%
    mapping (address => uint) public ratio;

    constructor() {
            owner = msg.sender;
    }

    function initProjectInfo(
        address[] memory addresss,
        uint[] memory uints
    ) public {
        require(isProjectInit[addresss[0]] == false, "project init");

        bool isSendFee = true;
        address projectAddress = addresss[0];
        uint amount = uints[0];

        bool isAddTokenOutSuccess = IERC20(projectAddress).transferFrom(msg.sender, address(this),amount);

        if (fee != 0) {
            isSendFee = IERC20(feeToken).transferFrom(msg.sender, owner, fee);
        }
        calcuDeflationRation(projectAddress);

        if (deflationContract[projectAddress] != 0) {
            amount = uint((amount *  (10**18 - deflationContract[projectAddress])) / (10**18));
        }

        if (isAddTokenOutSuccess && isSendFee) {
            projectPoolTotal[projectAddress] = amount - 1000*(deflationContract[projectAddress] + deflationUser[projectAddress])/10**18 - 2; // 初始化池子总量
            _projectBaseConfig(projectAddress, addresss, uints);
        }
    }

    function _projectBaseConfig(
        address projectAddress,
        address[] memory addresss,
        uint[] memory uints
    ) internal {
        /**
         * 地址信息
         * addresss[0] 项目方coin地址
         * addresss[1] 项目方钱包
         * addresss[2] 投资方coin地址
         */
        project[projectAddress] = addresss[0];
        projectOwner[projectAddress] = addresss[1];
        invest[projectAddress] = addresss[2];

        /**
         * uint 信息
         * uints[0]  配置-项目coin总额
         * 
         * uints[1] 活动开始时间
         * uints[2] 活动结束时间
         * uints[3] 线性释放时间戳
         * 
         * uints[4]  投资最大额
         * uints[5] 投资最小额
         * uints[6] 投资coin总额
         */
        projectAmount[projectAddress] = uints[0];
        startTime[projectAddress] = uints[1];
        endTime[projectAddress] = uints[2];
        freeLineTime[projectAddress] = uints[3];
        investBuyMax[projectAddress] = uints[4];
        investBuyMin[projectAddress] = uints[5];
        investAmount[projectAddress] = uints[6];

        isProjectInit[projectAddress] = true;
        ratio[projectAddress] = uint((uints[0] * 10**18) / uints[6]);

        if (deflationContract[projectAddress] != 0) {
            investAmount[projectAddress] = (uints[6] * (10**18 - deflationContract[projectAddress])) / (10**18);
            ratio[projectAddress] = uint((projectPoolTotal[projectAddress] * 10**18) / uints[6]);
        }
        require(ratio[projectAddress] != 0);
    }

    function calcuDeflationRation(address token) internal {
        IERC20 Token = IERC20(token);
        // transferFrom通缩
        uint calContractBefor = Token.balanceOf(address(this));
        Token.approve(address(this), 1000);
        Token.transferFrom(address(this), address(this), 1000);
        uint calContractAfter = Token.balanceOf(address(this));
        deflationContract[token] = ((calContractBefor - calContractAfter) * 10**18) / 1000;

        // transfert通缩
        uint calUserBefor = Token.balanceOf(address(this));
        Token.transfer(address(this), 1000);
        uint calUserAfter = Token.balanceOf(address(this));
        deflationContract[token] = ((calUserBefor - calUserAfter) * 10 ** 18) / 1000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setFee(uint _fee, address _feeAddress) external onlyOwner {
        fee = _fee;
        feeToken = _feeAddress;
    }
    modifier onlyProjectOwner(address _project) {
        address _owner = projectOwner[_project];
        require(_owner == msg.sender);
        _;
    }
}

