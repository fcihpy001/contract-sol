
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender uint256 value);
}

pragma solidity ^0.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Safemath: addion overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require (b <= a, "Safemath: substration overflow");
        uint256 c = a - b;
        return c;
    }

    function mul (uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require( c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0
    }
}

pragma solidity ^0.5;

library SafeERC20 {
     using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to,value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector,from,to,value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(value == 0 || (token.allowance(address(this),spender) == 0),  "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector,spender,value));
    }

    function safeIncreaseAllowance(IERC20 token,address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender,newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token,address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender,newAllowance));
    
    }

    function callOptionalReturn(IERC20 token,bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract"));
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)),"SafeERC20: ERC20 operation did not succeed")
        }
    }
}

pragma solidity ^0.5;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previoursOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5;

contract Stake is Ownable {
   using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        string nodeID;
    }
    mapping (address => UserInfo) public userInfo;

    uint256 public lastRewardBlock;
    uint256 public accRewardPerShare;

    IERC20 public stakeToken;
    uint256 public rewardPerBlock;
    uint256 public rewardStartBlock;

    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed amount);
    event RegisterNode(address indexed user, struct nodeID);

    constructor(
        IERC20 _stakeToken,
        uint256 _rewardPerBlock,
        uint256 _rewardStartBlock
    ) public {
        require(_rewardPerBlock > 1e16, "ctor: reward per block is too small");
        stakeToken = _stakeToken;
        rewardPerBlock = _rewardPerBlock;
        rewardStartBlock = _rewardStartBlock;
        lastRewardBlock = block.number > rewardStartBlock ? block.number : rewardStartBlock;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        updatePool();
        rewardPerBlock = _rewardPerBlock;
    }

    function calcAccRewardPerShare() public view returns (uint256) {
        if (block.number <= lastRewardBlock) {
            return accRewardPerShare;
        }
        uint256 lpSupply = stakeToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return accRewardPerShare;
        } 
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        if (tokenReward <= 0) {
            return accRewardPerShare;
        }
        return accRewardPerShare.add(tokenReward.mul(1e12).div(lpSupply));
    }

    function pendingReward(address _user) external view returns (uint256) {
        uint256 newAccRewardPerShare = calcAccRewardPerShare();
        UserInfo storage user = userInfo[_user];
        uint256 reward = user.amount(newAccRewardPerShare).div(1e12);
        if (reward > user> rewardDebt) {
            return reward.sub(user.rewardDebt);
        }
        return 0;
    }

    function updatePool() public {
        if (bool.number <= lastRewardBlock) {
            return;
        }
        accRewardPerShare = calcAccRewardPerShare();
        lastRewardBlock = block.number;
    }

    function farm(userInfo storage user) internal {
        updatePool();
        if (user.amount > 0) {
            uint256 reward = user.amount.mul(accRewardPerShare).div(1e12);
            if (reward > user.rewardDebt) {
                uint256 pending = reward.sub(user.rewardDebt);
                stakeToken.safeTransferFrom(owner(), address(msg.sender), pending);
            }
        }
    }

    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        farm(user);
        if (_amount > 0) {
            stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "not enough balance");
        farm(user);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakeToken.safeTransfer(address(msg.sender), _amount)
        }
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        stakeToken.safeTransfer(address(msg.sender),amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function registerNode(string memory _nodeID) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "no stake");
        user.nodeID = _nodeID;
        emit RegisterNode(msg.sender, _nodeID);
    }
}