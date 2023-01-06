// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { PausableZone } from "./PausableZone.sol";

import {
    PausableZoneControllerInterface
} from "./interfaces/PausableZoneControllerInterface.sol";

import {
    PausableZoneEventsAndErrors
} from "./interfaces/PausableZoneEventsAndErrors.sol";

import {
    Order,
    Fulfillment,
    OrderComponents,
    AdvancedOrder,
    CriteriaResolver,
    Execution
} from "../lib/ConsiderationStructs.sol";

import { SeaportInterface } from "../interfaces/SeaportInterface.sol";

/**
 * @title  PausableZoneController
 * @author cupOJoseph, BCLeFevre, stuckinaboot, stephankmin
 * @notice PausableZoneController enables deploying, pausing and executing
 *         orders on PausableZones. This deployer is designed to be owned
 *         by a gnosis safe, DAO, or trusted party.
 */
contract PausableZoneController is
    PausableZoneControllerInterface,
    PausableZoneEventsAndErrors
{
    // Set the owner that can deploy, pause and execute orders on PausableZones.
    address internal _owner;

    // Set the address of the new potential owner of the zone.
    address private _potentialOwner;

    // Set the address with the ability to pause the zone.
    address internal _pauser;

    // Set the immutable zone creation code hash.
    bytes32 public immutable zoneCreationCode;

    modifier isPauser() {
        if (msg.sender != _pauser && msg.sender != _owner) {
            revert InvalidPauser();
        }
        _;
    }
    
    constructor(address ownerAddress) {
        // Set the owner address as the owner.
        _owner = ownerAddress;

        // Hash and store the zone creation code.
        zoneCreationCode = keccak256(type(PausableZone).creationCode);
    }

    function createZone(bytes32 salt)
        external
        override
        returns (address derivedAddress)
    {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Derive the PausableZone address.
        // This expression demonstrates address computation but is not required.
        derivedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            zoneCreationCode
                        )
                    )
                )
            )
        );

        // Revert if a zone is currently deployed to the derived address.
        if (derivedAddress.code.length != 0) {
            revert ZoneAlreadyExists(derivedAddress);
        }

        // Deploy the zone using the supplied salt.
        new PausableZone{ salt: salt }();

        // Emit an event signifying that the zone was created.
        emit ZoneCreated(derivedAddress, salt);
    }

    function pause(address zone)
        external
        override
        isPauser
        returns (bool success)
    {
        // Call pause on the given zone.
        PausableZone(zone).pause(msg.sender);

        // Return a boolean indicating the pause was successful.
        success = true;
    }

    function cancelOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        OrderComponents[] calldata orders
    ) external override {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Create a zone object from the zone address.
        PausableZone zone = PausableZone(pausableZoneAddress);

        // Call cancelOrders on the given zone.
        zone.cancelOrders(seaportAddress, orders);
    }

    /**
     * @notice Execute an arbitrary number of matched orders on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders
     * to be cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Create a zone object from the zone address.
        PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
        executions = zone.executeMatchOrders{ value: msg.value }(
            seaportAddress,
            orders,
            fulfillments
        );
    }

    function executeMatchAdvancedOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable override returns (Execution[] memory executions) {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Create a zone object from the zone address.
        PausableZone zone = PausableZone(pausableZoneAddress);

        // Call executeMatchOrders on the given zone and return the sequence
        // of transfers performed as part of matching the given orders.
        executions = zone.executeMatchAdvancedOrders{ value: msg.value }(
            seaportAddress,
            orders,
            criteriaResolvers,
            fulfillments
        );
    }

    function transferOwnership(address newPotentialOwner) external override {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert OwnerCanNotBeSetAsZero();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    function cancelOwnershipTransfer() external override {
        // Ensure the caller is the current owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            revert CallerIsNotPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
        emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
        _owner = msg.sender;
    }

    function assignPauser(address pauserToAssign) external override {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Ensure the pauser to assign is not an invalid address.
        if (pauserToAssign == address(0)) {
            revert PauserCanNotBeSetAsZero();
        }

        // Set the given account as the pauser.
        _pauser = pauserToAssign;

        // Emit an event indicating the pauser has been assigned.
        emit PauserUpdated(pauserToAssign);
    }

    function assignOperator(
        address pausableZoneAddress,
        address operatorToAssign
    ) external override {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Create a zone object from the zone address.
        PausableZone zone = PausableZone(pausableZoneAddress);

        // Call assignOperator on the zone by passing in the given
        // operator address.
        zone.assignOperator(operatorToAssign);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    function pauser() external view override returns (address) {
        return _pauser;
    }
}
