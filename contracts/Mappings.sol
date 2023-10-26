// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mappings {
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