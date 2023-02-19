// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
    
contract Timestamp {
   uint public timestamp;
   function saveTimestamp() public {
      timestamp = block.timestamp;
   }
}