// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Consideration } from "./lib/Consideration.sol";

contract Seaport is Consideration {
   
   constructor(address conduitController) Consideration (conduitController) {};

   function _name() internal pure override returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0247, 0x07536561706f7274),
            return(0x20, 0x60)
        }
   }
   function _nameString() internal pure override returns (string memory) {
        return "Seaport";
   }
}
