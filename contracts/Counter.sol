// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint count; //Cannot be negative (uint is only positive)

    // Code inside the constructor will be called once during deployment of
    // the contract
    constructor() {
        count = 0;
    }
    // A view function, doesnt cost gas
    function getCount() public view  returns(uint){
        return count;
    }

    // A write function, have to pay gas (POST, PATCH/PUT)
    function incrementCount() public {
        count++;
    }
}