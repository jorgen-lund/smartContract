// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public count = 0; 

    // A write function, have to pay gas (POST, PATCH/PUT)
    function incrementCount() public {
        count++;
    }
}