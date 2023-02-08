// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SelectorClash {
    // 攻击是否成功
    bool public solved; 

    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    function executCrossChainTx(
        bytes memory _method,
        bytes memory _bytes
    ) public returns (bool success) {
        (success,) = address(this).call(
            abi.encodePacked(
                bytes4(keccak256(
                    abi.encodePacked(
                        _method, "(bytes, bytes, uint64)"
                    )
                )), abi.encode(_bytes)
            )
        );
    }

    function secretSelector() external pure returns(bytes4) {
        return bytes4(keccak256("putCurEpochConPubKeyBytes(bytes)"));
    }

    function hackSelector() external pure returns(bytes4) {
        return bytes4(keccak256("f1121318093(bytes,bytes,uint64)"));
    }
}