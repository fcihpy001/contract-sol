// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ZoneInterface } from "../interfaces/ZoneInterface.sol";
import { ZoneInteractionErrors } from "../interfaces/ZoneInteractionErrors.sol";

import {
    PausableZoneEventsAndErrors
} from "./interfaces/PausableZoneEventsAndErrors.sol";

import { SeaportInterface } from "../interfaces/SeaportInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Order,
    OrderComponents,
    Fulfillment,
    Execution
} from "../lib/ConsiderationStructs.sol";

import { PausableZoneInterface } from "./interfaces/PausableZoneInterface.sol";

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone.
 */

contract PausableZone is PausableZoneEventsAndErrors, ZoneInterface, PausableZoneInterface {
    address internal immutable _controller;
    address public operator;

    modifier isOperator() {
        if (msg.sender != operator && msg.sender != _controller ) {
            revert InvalidOperator();
        }
        _;
    }

    modifier isController() {
        if (msg.sender != _controller) {
            revert InvalidController();
        }
        _;
    }

    constructor() {
        _controller = msg.sender;
        emit Unpaused();
    }

    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external override isOperator returns (bool cancelled) {
        cancelled = seaport.cancel(orders);
    }

    function pause(address payee) external override isController {
        emit Paused();

        selfdestruct(payable(payee));
    }

    function assignOperator(address operatorToAssign)
        external override isController {
        if (operatorToAssign == address(0)) {
            revert PauserCanNotBeSetAsZero();
        }
        operator = operatorToAssign;
        emit OperatorUpdated(operatorToAssign);
    }

    function executeMatchOrders(
        SeaportInterface seaport,
        Order[] calldata orders,
        Fulfillment[] calldata Fulfillments
    ) external payable override isOperator returns (Execution[] memory executions) {
        executions = seaport.matchOrders { value: msg.value }(
            orders,
            Fulfillments
        );
    }

    function executeMatchAdvancedOrders(
        SeaportInterface seaport,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) 
        external
        payable 
        override
        isOperator
        returns (Execution[] memory executions)
    {
        executions = seaport.matchAdvanceOrders {value: msg.value}(
            orders,
            criteriaResolvers,
            fulfillments
        );
    }

    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external pure override returns (bytes4 validOrderMagicValue) {
        orderHash;
        caller;
        offerer;
        zoneHash;

        validOrderMagicValue = ZoneInterface.isValidOrder.selector;
    }

    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata prioOrderHashes,
        CriteriaResolver[] calldata criteriaResolvers
    ) external pure override returns (bytes4 validOrderMagicValue) {
        orderHash;
        caller;
        order;
        prioOrderHashes;
        criteriaResolvers;

        validOrderMagicValue = ZoneInterface.isValidOrder.selector;
    }

}