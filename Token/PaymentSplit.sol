// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 分账合约 
 * @dev 这个合约会把收到的ETH按事先定好的份额分给几个账户。收到ETH会存在分账合约中，需要每个受益人调用release()函数来领取。
 */
contract PaymentSplit {

    // 增加受益人
    event PayeeAdded(address account, uint256 shares);
    // 受益人提款
    event PaymentReleased(address to, uint256 amount);
    // 合约收款
    event PaymentReceived(address from, uint256 amount);

    uint256 public totalShares;      //总份额
    uint256 public totalReleased;    //总支付
    address[] public payees; // 受益人数组

    mapping(address => uint256) public shares; //每个受益的份额
    mapping(address => uint256) public released; //支付给每个收益人的金额

    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        require(_payees.length == _shares.length,"PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        
        // 调用_addPayee，更新受益人地址payees、受益人份额shares和总份额totalShares
        for (uint256 i = 0; i < _payees.length; i ++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    // 回调函数，收到ETH释放PaymentReceived事件
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    // 为有效受益人地址_account分帐，相应的ETH直接发送到受益人地址。任何人都可以触发这个函数，但钱会打给account地址。
    function release(address payable _account) public virtual {
        // account必须是有效受益人
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // 计算account应得的eth
        uint256 payment = releaseable(_account);
        // 应得的eth不能为0
        require(payment != 0,"PaymentSplitter: account is not due payment");

        // 更新总支付totalReleased和支付给每个受益人的金额released
        totalReleased += payment;
        released[_account] += payment;

        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }


    // 计算一个账户能够领取的eth。
    function releaseable(address _account) public view returns (uint256) {
        // 计算分账合约总收入totalReceived
        uint256 totalReceived = address(this).balance + totalReleased;
        // 调用_pendingPayment计算account应得的ETH
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev 根据受益人地址`_account`, 分账合约总收入`_totalReceived`和该地址已领取的钱`_alreadyReleased`，计算该受益人现在应分的`ETH`。
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // account应得的ETH = 总应得ETH - 已领到的ETH
        return (_totalReceived * shares[_account] / totalShares - _alreadyReleased);
    }

    // 新增受益人_account以及对应的份额_accountShares。只能在构造器中被调用，不能修改
    function _addPayee(
        address _account,
        uint256 _accountShares
    ) private {
        require(_account != address(0),  "PaymentSplitter: account is the zero address");
        require( _accountShares > 0, "PaymentSplitter: shares are 0");
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");

        payees.push(_account);
        shares[_account] = _accountShares;
        totalShare += _accountShares;

        emit PayeeAdded(_account, _accountShares);
    }
}