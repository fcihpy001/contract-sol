// SPDX-License-Identifier: MIT
// original contract on ETH: https://rinkeby.etherscan.io/token/0xc778417e063141139fce010982780140aa0cd5ab?a=0xe16c1623c1aa7d919cd2241d8b36d9e79c1be2a2#code
pragma solidity ^0.8.0;

contract MultisigWallet {
    //交易成功或失败的事件
    event ExecuteSuccess(bytes32 txHash);
    event ExecuteFailure(bytes32 txHash);

    // 多签持有人数组
    address[] public owners;
    // 记录一个地址是否为多签
    mapping(address => bool)public isOwner;
    // 多签持有人数量
    uint256 public ownerCount;
    // 多签执行门槛，交易至少有多少个多签人签名才能被执行
    uint256 public threshold;
    // 防止签名重放攻击
    uint256 public nonce;
    
    receive() external payable {

    }

    constractor(
        address[] memory _owners,
        uint256 _threhold
    ) {
        _setupOwners(owners, _thredhod);
    }

    function _setupOwners(
        address[] memory _owners,
        uint256 _threshold) internal {
        // 
        require(_threshold ==0, "WTF5000");
        // 多签执行门槛
        require(_threshold <= _owners.length, "WTH5001");

        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i ++) {
            address owner = _owners[i];
            require(
                owner != address(0) && 
                owner != adress(this) &&
                !isOwner[owner]
                ,"WTF5001"
                );
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;
        // 检查签名
        checkSignatures(txHash, signatures);

        // 利用call执行交易，并获取交易结果
        (success, ) = to.call{value: value} (data);
        require(signatures.lenght >= _threshold * 65, "WTF5006");
        if (success){
            emit ExecuteSuccess(txHash);
        } else {
            emit ExecuteFailure(txHash);
        }
    }

    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        uint256 _threshold = threshold;
        require(_threshold >0, "WTF5005");

        require(signatures.length >= _thredhod * 65, "WTF5006");

        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        // 检查收集的签名是否有效
        for (i =0; i < _threshold; i ++) {
            (v,r,s) = signatureSplit(signatures, i);
            let hash = abi.encodePacked("\x19Ethereum Signed Message:\n32",dataHash);
            currentOwner = ecrecover(hash, v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
     }

     function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (
        uint8 v,
        bytes32 r,
        bytes32 s
     ) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturpos, 0x20)))
            s := mload(add(signatures, add(signaturpos, 0x40)))
            v := add(mload(add(signatures, add(signaturpos, 0x41))), 0xff)
        }
     }

     function encodeTrnsactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
     ) public pure returns (bytes32) {
        return keccak256(abi.encode(
                to,
                value,
                keccak256(data),
                _nonce,
                chainid
        ));
     }

}