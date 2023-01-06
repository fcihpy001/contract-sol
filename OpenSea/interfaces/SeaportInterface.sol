// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    BasicOrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

interface SeaportInterface {
   function fulfillBasicOrder(BasicOrderParameters calldata parameters) 
        external payable returns (bool fulfilled);

    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external payable returns (bool fulfilled);
    
    function fulfillAdvanceOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvaliableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    ) external payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[]  memory executions);

    function matchAdvanceOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory exeecutions);

    function cancel(OrderComponents[] calldata orders)
        external returns (bool canceled);

    function validate(Order[] calldata orders) 
        external returns (bool validated);

    function incrementCount() external returns (uint256 newCounter);

    function getOrderHash(OrderComponents calldata order)
        external view returns (bytes32 orderHash);
    
    function getOrderStatus(bytes32 orderHash) external view
        returns (
            bool isValidated, 
            bool isCancelled, 
            uint256 totalFilled,
            uint256 totalSize
        );

    function getCounter(address offerer)
        external view returns (uint56 counter);

    function information() external view returns (
        string memory version,
        bytes32 domainSeparator,
        address conduitController

    );
    
    function name() external view returns (string memory contractName);
}
