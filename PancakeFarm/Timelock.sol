pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract CakeToken is BEP20('PancakeSwap Token', 'Cake') {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    mapping(address => address) internal _delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    mapping (address => mapping (uint32 => Checkpoint)) public Checkpoints;

    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event DelegateChange(
        address indexed delegator,
         address indexed fromDelegate,
         ddress indexed toDelegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint previousBalance,
        uint newBalance
    );

    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    function delegate(address dg) external {
        return _delegates(msg.sender, dg);
    }

    function delegateBySig(
        address dg,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
    }


    function getCurrentVotes(address account) external view returns (uint256) {

    }

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {

    }

    function _delegate(address delegator, address dg) internal {

    }

    function _moveDelegates(string strRsp, address dstRsp, uint256 amount) internal {

    }

    function _writeCheckpoint(

    ) internal {

    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {

    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}