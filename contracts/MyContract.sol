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


    //Mappings (Dict, hashMap, etc, equivalent)
    mapping(uint => string) names;

    constructor() {
        names[1] = "John";
        names[2] = "Johan Petter";
        names[3] = "Jorny";
    }


    // Example1 
    mapping(uint => Book) public books;
    
    struct Book {
        string title;
        string author;
    }

    function addBook(
        uint _id,
        string memory _title,
        string memory _author
    ) public {
        books[_id] = Book(_title, _author);
    }

    //Example 2 


    mapping(uint => Fruit) public fruits;
    
    struct Fruit {
        string name;
        string origin;
    }

    function addFruit(
        uint _id,
        string memory _name,
        string memory _origin
    ) public {
        fruits[_id] = Fruit(_name, _origin);
    }

    // Example 3
    struct Liquor {
        uint percent;
        string category;
        string brand; 
        string name;
    }

    mapping(uint => Liquor) public liquors;

    function addLiquor(
        uint _id,
        uint _percent,
        string memory _category,
        string memory _brand,
        string memory _name
    ) public {
        liquors[_id] = Liquor(_percent, _category, _brand, _name);
    }

    //Mappings of mappings, aka. Nested mappings (normal with Tokens, NFTs)
    // This would give all the Liquors owned by the address
    mapping(address => mapping(uint => Liquor)) public myLiquors;
    
    function addMyLiquor(
        uint _id,
        uint _percent,
        string memory _category,
        string memory _brand,
        string memory _name
    ) public {
        //msg is a global variable, sender is the one calling the function (like the address)
        myLiquors[msg.sender][_id] = Liquor(_percent, _category, _brand, _name);
    }

}