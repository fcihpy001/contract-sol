// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Timelock {
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed trarget,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );

    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );

    event QueueTranscation(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );
    
    event NewAdmin(address indexed newAdmin);

    address public admin;
    uint public constant GRANCE_PERIOD = 7 days;  //交易有效期，过期交易作废
    uint public delay; //交易锁定时间
    mapping (bytes32 => bool) public queuedTransactions;  //所有在时间锁队列中的交易

    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }

    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }

    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

    function queueTranscation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner returns (bytes32) {
        // 检查：交易执行时间满足锁定时间
        require(executeTime >= getBlockTimestamp() + delay,"Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        queuedTransactions[txHash] = true;
        emit QueueTranscation(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    function cancelTranscation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        require(queuedTransactions[txHash],"Timelock::cancelTransaction: Transaction hasn't been queued.");
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }


    function executeTranscation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 检查：交易是否在时间锁队列中
        require(queuedTransactions[txHash],"Timelock::executeTransaction: Transaction hasn't been queued.");
        // 检查：达到交易的执行时间
        require(getBlockTimestamp() >= executeTime,"Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // 检查：交易没过期
        require(getBlockTimestamp() < executeTime + GRANCE_PERIOD,"Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(
                keccak256(bytes(signature))
            ), data);
        }

        // 利用call执行交易
        (bool success, bytes memory returnData) = target.call{
            value: value
        }(callData);

        require(success, "Timelock::executeTransaction: Transaction execution reverted.");
        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);
        return returnData;
    }



    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                target,
                value,
                signature,
                data,
                executeTime
            )
        );
    }
}