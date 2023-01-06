pragma solidity 0.8;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

contract BnbStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // info of each user
    struct UserInfo {
        // lp token amount
        uint256 amount;
        uint256 rewardDebt;
        bool inBlackList;
    }

    // info of each pool
    struct PoolInfo {
        // address of LP token contract
        IBEP20 lpToken;
        // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 allocPoint;
        // Last block number that CAKEs distribution occurs.
        uint256 lastRewardBlock;
        // Accumulated CAKEs per share, times 1e12
        uint256 accCakePerShare;
    }

    IBEP20 public rewardToken;

    address public adminAddress;
    address public immutable WBNB;
    uint256 public rewardPerBlock;

    PoolInfo[] public poolInfo;
    mapping (address => UserInfo) public userInfo;

    // limit 10 BNB here
    uint256 public limitAmount = 10000000000000000000;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, int256 amount);

    constructor (
        IBEP20 _lp,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bounsEndBlock,
        address _adminAddress,
        address _wbnb
    ) public {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bounsEndBlock;
        adminAddress = _adminAddress;
        WBNB = _wbnb;

        poolInfo.push(PoolInfo {
            lpToken: _lp,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        });

        totalAllocPoint = 1000;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    receive() external payable {
        assert(msg.sender == WBNB);
    }

    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setBlackList(address _blackListAddress) public onlyAdmin {
        userInfo[_blackListAddress].inBlackList = true;
    }

    function removeBlackList(address _blackListAddress) public onlyAdmin {
        userInfo[_blackListAddress].inBlackList = false;
    }

    function setLimitAmount(uint256 _amount) public onlyOwner {
        limitAmount = _amount;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.multiplier(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;

    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.lenth; pid ++) {
            updatePool(pid);
        }
    }

    function deposit() public payable {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount.add(msg.value) <= limitAmount, 'exceed the top' );
        require(!user.inBlackList, 'in black list');

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        if (msg.value > 0) {
            IWBNB(WBNB).deposit { value: msg.value }();
            assert(IWBNB(WBNB).transfer(address(this), msg.value));
            user.amount = user.amount.add(msg.value);
        }

        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, msg.value);
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool succcess, ) = to.call{gas: 23000, value: value}("");
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        userInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0 && !user.inBlackList) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IWBNB(WBNB).withdraw(_amount);
            safeTransferBNB(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        
        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
}