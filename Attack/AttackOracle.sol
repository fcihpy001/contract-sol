pragma solidity ^0.8.4;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import '../Swap/uniswapv2/UniswapV2.sol';



contract AttackOracle is Test {
    address private constant alice = address(1);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router router;
    IWETH private weth = IWETH(WETH);
    IBUSD private busd = IBUSD(BUSD);
    string MAINNET_RPC_URL;
    oUSD ousd;
    
    function setUp() public{

    }

    function testOracleAttack() public {

    }

    function swapBUSDtoWETH(uint amountIn, uint amountOutMin) public returns (uint amountOut) {

    }

    
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IBUSD is IERC20 {
    function balanceOf(address account) external view returns(uint);
}