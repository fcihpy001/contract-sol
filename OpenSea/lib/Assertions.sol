// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { OrderParameters } from "./ConsiderationStructs.sol";

import { GettersAndDerivers } from "./GettersAndDerivers.sol";

import {
    TokenTransferrerErrors
} from "../interfaces/TokenTransferrerErrors.sol";

import { CounterManager } from "./CounterManager.sol";

import "./ConsiderationConstants.sol";

contract Assertions is GettersAndDerivers, CounterManager, TokenTransferrerErrors {

    constructor (address conduitController) GettersAndDerivers(conduitController) {}

    function _assertConsiderationLengthAndGetOrderhash(
        OrderParameters memory orderParameters
    ) internal view returns (bytes32) {
        _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );
        return _deriveOrderHash(orderParameters, _getCounter(orderParameters.offerer));
    }

    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {
        if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {
            revert MissingOriginalConsiderationItems();
        }
    }

    function _assertNonZeroAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert MissingItemAmount();
        }
    }

    function _assertValidBasicOrderParameters() internal pure {
        bool validOffsets;

        assembly {
            validOffsets := and(
                eq(
                    calldataload(BasicOrder_parameters_ptr),
                    BasicOrder_parameters_ptr
                ),
                eq(
                    calldataload(BasicOrder_additionalRecipients_head_cdPtr),
                    BasicOrder_additionalRecipients_data_cdPtr
                )
            )

            validOffsets := and(
                validOffsets,
                eq(
                    calldataload(BasicOrder_signature_cdPtr),
                    // Derive expected offset as start of recipients + len * 64.
                    add(
                        BasicOrder_signature_ptr,
                        mul(
                            // Additional recipients length at calldata 0x264.
                            calldataload(
                                BasicOrder_additionalRecipients_length_cdPtr
                            ),
                            // Each additional recipient has a length of 0x40.
                            AdditionalRecipients_size
                        )
                    )
                )
            )

            validOffsets := and(
                validOffsets,
                lt(
                    // BasicOrderType parameter at calldata offset 0x124.
                    calldataload(BasicOrder_basicOrderType_cdPtr),
                    // Value should be less than 24.
                    BasicOrder_basicOrderType_range
                )
            )
        }
        if (!validOffsets) {
            revert InvalidBasicOrderParameterEncoding();
        }
    }
}
