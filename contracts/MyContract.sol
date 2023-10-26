// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    // State Variables are stored on the blockchain, saved forever. 
    uint public myUint = 1;
    int public myInt = 1;
    // On blockchain we care about size alot, hence uintXX
    uint256 public myUint256 = 1;  
    uint8 public myUint8 = 1;

    // Strings
    string public myString = "Hello, World!";

    // Treats your string like an array, more flexibility than string
    bytes32 public myBytes32 = "Hello, World!";

    //Address, not a real address
    // address public myAddress = 0x557923367012Ac66E8630fe805114d63477A7B36;

    // Structs, own custom datatype. 
    struct MyStruct {
        uint256 myUint256;
        string myString;
    }

    MyStruct public myStruct = MyStruct(1, "Hello world!");


    //Local Variables
    // Exist inside functions
    function getValue() public pure returns (uint) {
        uint value = 1;
        return value;
    }
}