// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    constructor() payable {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory {
    mapping(address => mapping(address => address)) public pairInfo;
    address[] public allPairs;

    function creatPair(address tokenA, address tokenB) external returns (address pairAddr) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //避免tokenA和tokenB相同产生的冲突
        //将tokenA和tokenB按大小排序
        (address _token0, address _token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // 计算用tokenA和tokenB地址计算salt
        bytes32 salt = keccak256(abi.encodePacked(_token0, _token1));

        Pair pair = new Pair{ salt: salt };
        pair.initialize(tokenA, tokenB);
        allPairs.push(pairAddr);
        pairInfo[tokenA][tokenB] = pairAddr;
        pairInfo[tokenB][tokenA] = pairAddr;
    }

    // 计算合约地址
    function calculateAddr(address tokenA, address tokenB) public view returns (address predictAddr) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //避免tokenA和tokenB相同产生的冲突
        
        //将tokenA和tokenB按大小排序
        (address _token0, address _token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // 计算用tokenA和tokenB地址计算salt
        bytes32 salt = keccak256(abi.encodePacked(_token0, _token1));

        predictAddr = address(uint160(uint(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )
        ))));
    }
}