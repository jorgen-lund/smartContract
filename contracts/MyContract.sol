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

    // Arrays 
    uint[] public uintArray = [1, 2, 3];
    string[] public stringArray = ["John", "Johnny", "Johnson"];
    string[] public values;
    //2d array
    uint256[][] public array2D = [[1, 2, 3], [4, 5, 6]];


    //memory: It tells us where the data is stored. Solidity has three places where 
    // it can store data – storage, memory, and stack. In this case, memory means that _value 
    // is a temporary variable, and it will not persist across function calls.
    //_value: This is the name of the parameter. The underscore (_) prefix is a common 
    // convention in Solidity to differentiate between function parameters and global variables.
    function addValue(string memory _value) public {
        values.push(_value);
    }

    function valueCount() public view returns(uint) {
        return values.length;
    }
}