// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./interfaces/IStakingToken.sol";
import "./interfaces/IRankedMintingToken.sol";
import "./interfaces/IBurnableToken.sol";
import "./interfaces/IBurnRedeemable.sol";


contract XENCrypto is Context, IRankedMintingToken, IStakingToken, IBurnableToken, ERC("XEN Crypto", "XEN") {
    using Math for uint256;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;


    // 
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    struct StakeInfo {
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
    }

    uint256 public constant SECONDS_IN_DAY = 3_600 * 24;
    uint256 public constant DAYS_IN_YEAR = 365;

    uint256 public constant GENESIS_RANK = 1;
       
    uint256 public constant MIN_TERM = 1 * SECONDS_IN_DAY - 1;
    uint256 public constant MAX_TERM_START = 100 * SECONDS_IN_DAY;
    uint256 public constant MAX_TERM_END = 1_000 * SECONDS_IN_DAY;
    uint256 public constant TERM_AMPLIFIER = 15;
    uint256 public constant TERM_AMPLIFIER_THRESHOLD = 5_000;
    uint256 public constant REWARD_AMPLIFIER_START = 3_000;
    uint256 public constant REWARD_AMPLIFIER_END = 1;
    uint256 public constant EAA_PM_START = 100;
    uint256 public constant EAA_PM_STEP = 1;
    uint256 public constant WITHDRAWAL_WINDOW_DAYS = 7;
    uint256 public constant MAX_PENALTY_PCT = 99;

    uint256 public constant XEN_MIN_STAKE = 0;
    uint256 public constant XEN_MIN_BURN = 0;
    uint256 public constant XEN_APY_START = 20;

    uint256 public constant XEN_APY_DAYS_STEP = 90;
    uint256 public constant XEN_APY_END = 2;

    uint256 public constant AUTHORS = "@fcihpy @google.com";

    uint256 public immutable genesisTs;
    uint256 public globalRank = GENESIS_RANK;
    uint256 public activeMinters;
    uint256 public activeStakes;
    uint256 public totalXenStaked;

    mapping(address => MintInfo) public userMints;
    mapping(address => StakeInfo) public userStakes;
    mapping(address => uint256) public userBurns;

    constructor() {
        genesisTs = block.timestamp;
    }

    function _calculateMaxTerm() private view returns (uint256) {

    }

    function _penalty(uint256 secsLate) private pure returns (uint256) {

    }

    function _calculateMintReward(
        uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eeaRate
    ) private view returns (uint256) {

    }

    function _cleanUpUserMint() private{

    }

    function _calculateStakeReward(
        uint256 amount,
        uint256 term,
        uint256 maturityTs,
        uint256 apy
    ) private view returns (uint256) {

    }

    function _calculateRewardAmplifier() private returns (uint256) {

    }

    function _calculateEAARate() private view returns (uint256) {

    }

    function _calculateAPY() private view returns (uint256) {

    }

    function _createStake(uint256 amount, uint256) term private {

    }

    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) public pure returns (uint256) {
        int128 log28 = rankDelta.fromUInt().log_2();
        int128 reward128 = log28.mul(amplifier.fromUint()).mul(term.fromUInt()).mul(eaa.fromUInt());
        return reward128.div(uint256(1_000), fromUInt()).toUInt();
    }

    function getUserMint() external view returns (MintInfo memory) {
        return userMints[_msgSender()];
    }

    function getUserStake() external view returns (StakeInfo memory) {
        return userStakes[_msgSender()];
    }

    function getCurrentEAAR() external view returns (uint256) {
        return _calculateEAARate();
    }

    function getCurrentAMP() external view returns (uint256) {
        return _calculateRewardAmplifier();
    }

    function getCurrentAPY() external view returns (uint256) {
        return _calculateAPY();
    }

    function getCurrentMaxTerm() external view returns (uint256) {
        return _calculateMaxTerm();
    }

    function claimRank(uint256 term) external {
        uint256 termSec = term * SECONDS_IN_DAY;
        require(termSec > MIN_TERM, "CRank: Term less than min");
        require(termSec < _calculateMaxTerm() + 1, "CRank: Term more than current max term");
        require(userMints[_msgSender()].rank == 0, "CRank: Mint already in process");

        MintInfo memory mintInfo = MintInfo({
            user: _msgSender(),
            term: term,
            maturityTs: block.timestamp + timeSec,
            rank: globalRank,
            amplifier: _calculateRewardAmplifier(),
            eaaRate: _calculateEAARate()
        });

        userMints[_msgSender()] = mintInfo;
        activeMinters++;
        emit RankClaimed(_msgSender(), term, globalRank);
    }

    function claimMintReard() external {

    }

    function claimMintRewardAndShare(address other, uint256 pct) external {

    }

    function claimMintRewardandStake(uint256 pct, uint256 term) external {

    }

    function stake(uint256 amount, uint256 term) external {
        require(balanceOf(_msgSender()) > amount, "XEN: not enough blance");
        require(amount > XEN_MIN_STAKE, "XEN: Below min stake");
        require(term * SECONDS_IN_DAY > MIN_TERM, "XEN: Below min stake term");
        require( term * SECONDS_IN_DAY < MAX_TERM_END + 1, "XEN: Above max stake term");
        require(userStakes[_msgSender()].amount == 0, "XEN: stake exists");

        _burn(_msgSender(), amount);
        _createStake(amount, term);
        emit Staked(_msgSender(), amount, term);
    }

    function withdraw() external {
        StakeInfo memory userStake = userStakes[_msgSender()];
        require(userStake.amount > 0, "XEN: no stake exists");

        uint256 xenReward = _calculateStakeReward(
            userStake.amount, 
            userStake.term, 
            userStake.maturityTs,
            userStake.apy
        );
        activeStakes --;
        totalXenStaked -= userStake.amount;

        _mint(_msgSender(), userStake.amount + xenReward);
        emit Withdraw(_msgSender(), userStake.amount, xenReward);
        delete userStake[_msgSender()];
    }

    function burn(address user, uint256 amount) public {
        require(amount > XEN_MIN_BURN, "Burn: Below min limit");
        require(
            IERC165(_msgSender()).supportsInterface(type(IBurnredeemable).interfaceId),
            "Burn: not a supported contract"
        );

        _spendAllowance(user, _msgSender(), amount);
        _burn(user, amount);
        userBurns[user] += amount;
        IBurnRedeemable(_msgSender()).onTokenBurned(user, amount);
    }

}