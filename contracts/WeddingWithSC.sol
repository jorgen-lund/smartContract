// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract EngagementRegistry is ERC721Enumerable {
    
    address public authorisedAccount;

    struct Engagement {
        Spouse spouse1;
        Spouse spouse2;
        uint256 weddingDate;
        bool isRevoked;
        bool spouse1ConfirmedMarriage;
        bool spouse2ConfirmedMarriage;
        uint8 burnCertificate;
    }

    struct Spouse {
        address spouseAddress;
        uint256 id;
        string name;
        bool isEngaged;
        bool isMarried;
    }

    struct GuestList {
        address[] proposedGuests;
        bool spouse1Confirmed;
        bool spouse2Confirmed;
        mapping(address => bool) hasVotedAgainst;
        uint256 votesAgainst;
    }
    mapping(address => Spouse) public spouses;
    mapping(address => Engagement) public engagements;
    mapping(address => GuestList) public guestLists;

    // EVENTS
    event EngagementRegistered(address spouse1, address spouse2, uint256 weddingDate);
    event EngagementRevoked(address caller, uint256 revokedDate);
    event GuestListProposed(address spouse, address[] guests);
    event GuestListConfirmed(address spouse);
    event MarriageConfirmed(address spouse1, address spouse2);
    event GuestVotedAgainst(address guest, address spouse);
    event WeddingInvalidated(address spouse);
    event token(uint256 token);

    // MODIFIERS
    modifier notEngaged(address _spouse) {
        require(
            !spouses[msg.sender].isEngaged && !spouses[_spouse].isEngaged,
            "One or both of the spouses are already engaged."
        );
        _;
    }

    modifier isEngaged(address _spouseAddress) {
        require(spouses[_spouseAddress].isEngaged == true, "Address not engaged.");
        _;
    }


    modifier isEngagedParty(address _spouseAddress) {
        Engagement memory engagement = engagements[_spouseAddress];
        require(
            msg.sender == spouses[engagement.spouse1.spouseAddress].spouseAddress || 
            msg.sender == spouses[engagement.spouse2.spouseAddress].spouseAddress,
            "Caller must be one of the engaged parties"
        );
        _;
    }

    modifier notSameAddress(address _spouse) {
        require(msg.sender != _spouse, "Cannot engage to oneself");
        _;
    }
    
    modifier isNotRevoked(address _spouse) {
        require(engagements[_spouse].isRevoked == false, "The engagement is already revoked.");
        _;
    }

    modifier isNotMarried(address _spouseAddress) {
        require(!spouses[_spouseAddress].isMarried,"Already married");
        _;
    }

    modifier isConfirmedGuest(address _spouse) {
        require(isGuestConfirmed(_spouse, msg.sender), "Not a confirmed guest");
        _;
    }

    modifier hasNotVoted(address _spouse) {
        require(!guestLists[_spouse].hasVotedAgainst[msg.sender], "Already voted");
        _;
    }

    // TODO: Modifiers for date, musst be fixed as solidity is weird.
    modifier futureDate(uint256 _date) {
        require(_date > block.timestamp, "Date must be in the future");
        _;
    }

    modifier isBeforeWeddingDate(address _spouse) {
        Engagement memory engagement = engagements[_spouse];
        require(block.timestamp < engagement.weddingDate - 1 days, "The wedding date is already here");
        _;
    }

    modifier isVotingPeriod(address _spouse) {
        Engagement memory engagement = engagements[_spouse];
        require(block.timestamp >= engagement.weddingDate - 1 days, "Voting not yet open");
        require(block.timestamp < engagement.weddingDate, "Voting closed");
        _;
    }

    modifier weddingDateHasArrived(address _spouse) {
        require(block.timestamp >= engagements[_spouse].weddingDate, "Wedding date not yet arrived");
        _;
    }

    modifier weddingDateHasNotPassed(address _spouse) {
        require(block.timestamp < engagements[_spouse].weddingDate + 1 days, "Wedding date passed");
        _;
    }


// FUNCTIONS
    constructor() ERC721("EngagementRegistry", "ENR"){
        // add an authorized account
        authorisedAccount = (0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C);
    }

    //ENGAGEMENT (TASK 1)

    function registerEngagement(
        string memory _proposerName,
        uint256 _proposerID, address _proposeeAddress, 
        string memory _proposeeName, uint256 _proposeeID,
        uint256 _weddingDate)
        external notSameAddress(_proposeeAddress) notEngaged(_proposeeAddress){
        // Ensure neither party is already engaged or married

        // Update Spouse structs for both the proposer and the proposee
        spouses[msg.sender] = Spouse({
            spouseAddress: msg.sender,
            id: _proposerID,
            name: _proposerName,
            isEngaged: true,
            isMarried: false
        });

        spouses[_proposeeAddress] = Spouse({
            spouseAddress: _proposeeAddress,
            id: _proposeeID,
            name: _proposeeName,
            isEngaged: true,
            isMarried: false
        });

        // Create the Engagement instance and store it in the contract's state
        engagements[msg.sender] = Engagement({
            spouse1: spouses[msg.sender],
            spouse2: spouses[_proposeeAddress],
            weddingDate: _weddingDate,
            isRevoked: false,
            spouse1ConfirmedMarriage: false,
            spouse2ConfirmedMarriage: false,
            burnCertificate: 0
        });

        // Also map the engagement to the proposee's address
        engagements[_proposeeAddress] = engagements[msg.sender];
    }


    // PARTICIPATION (TASK 2)
    function proposeGuestList(address[] calldata _guests) external isEngaged(msg.sender) isEngagedParty(msg.sender) {
        address guestListKey = getGuestListKey(msg.sender);

        GuestList storage guestList = guestLists[guestListKey];

        guestList.proposedGuests = _guests;
        guestList.spouse1Confirmed = false;
        guestList.spouse2Confirmed = false;

        emit GuestListProposed(msg.sender, _guests);
    }


    function confirmGuestList() external isEngaged(msg.sender) isEngagedParty(msg.sender) {
        address guestListKey = getGuestListKey(msg.sender);

        GuestList storage guestList = guestLists[guestListKey];

        if (msg.sender == engagements[msg.sender].spouse1.spouseAddress) {
            guestList.spouse1Confirmed = true;
        } else {
            guestList.spouse2Confirmed = true;
        }

        if (guestList.spouse1Confirmed && guestList.spouse2Confirmed) {
            emit GuestListConfirmed(msg.sender);
        }
    }

    function getGuestListKey(address _spouse) isEngaged(_spouse) internal view returns (address) {
        Engagement memory engagement = engagements[_spouse];
        return engagement.spouse1.spouseAddress;
    }

    function isGuestConfirmed(address _spouse, address _guest) isEngaged(_spouse) public view returns (bool) {
        address guestListKey = getGuestListKey(_spouse);
        GuestList storage guestList = guestLists[guestListKey];

        if (guestList.spouse1Confirmed && guestList.spouse2Confirmed) {
            for (uint8 i = 0; i < guestList.proposedGuests.length; i++) {
                if (guestList.proposedGuests[i] == _guest) {
                    return true;
                }
            }
        }
        return false;
    }

    // REVOKE ENGAGEMENT (PART 3)
    function revokeEngagement() external isEngaged(msg.sender) isNotRevoked(msg.sender) {
        Engagement storage engagement = engagements[msg.sender];

        delete engagements[engagement.spouse1.spouseAddress];
        delete engagements[engagement.spouse2.spouseAddress];
        spouses[engagement.spouse1.spouseAddress].isEngaged = false;
        spouses[engagement.spouse2.spouseAddress].isEngaged = false;

        emit EngagementRevoked(msg.sender, block.timestamp);
    }


    // MARRY (PART 4)
    function marry() external 
        isEngaged(msg.sender) 
        isNotRevoked(msg.sender)
        isNotMarried(msg.sender)
    {
        Engagement storage engagement = engagements[msg.sender];

        // Confirm marriage for the caller
        if (msg.sender == engagement.spouse1.spouseAddress) {
            engagement.spouse1ConfirmedMarriage = true;
        } else if (msg.sender == engagement.spouse2.spouseAddress) {
            engagement.spouse2ConfirmedMarriage = true;
        }

        // Check if both have confirmed the marriage
        if (engagement.spouse1ConfirmedMarriage && engagement.spouse2ConfirmedMarriage) {
            // Update the married status in the Spouse structs
            spouses[engagement.spouse1.spouseAddress].isMarried = true;
            spouses[engagement.spouse2.spouseAddress].isMarried = true;

            // Emit an event indicating the marriage is confirmed
            emit MarriageConfirmed(engagement.spouse1.spouseAddress, engagement.spouse2.spouseAddress);

            // Minting tokens representing the marriage (if applicable)
            _safeMint(engagement.spouse1.spouseAddress, totalSupply() + 1);
            _safeMint(engagement.spouse2.spouseAddress, totalSupply() + 1);
        }
    }


    // VOTING (PART 5)
    function voteAgainstWedding(address _spouse) external 
        isEngaged(_spouse) 
        isNotRevoked(_spouse)
        isNotMarried(_spouse)
        isConfirmedGuest(_spouse)
        hasNotVoted(_spouse)
    {
        GuestList storage guestList = guestLists[_spouse];

        guestList.hasVotedAgainst[msg.sender] = true;
        guestList.votesAgainst++;
        emit GuestVotedAgainst(msg.sender, _spouse);

        _checkAndInvalidateWedding(_spouse);
    }


    function _checkAndInvalidateWedding(address _spouse) internal 
        isEngaged(_spouse)
        isNotMarried(_spouse)
    {
        GuestList storage guestList = guestLists[_spouse];
        Engagement storage engagement = engagements[_spouse];

        uint256 confirmedGuestCount = guestList.proposedGuests.length;
        uint256 requiredVotesToInvalidate = (confirmedGuestCount + 1) / 2;

        if (guestList.votesAgainst >= requiredVotesToInvalidate) {
            engagement.isRevoked = true;

            spouses[engagement.spouse1.spouseAddress].isEngaged = false;
            spouses[engagement.spouse2.spouseAddress].isEngaged = false;

            emit WeddingInvalidated(engagement.spouse1.spouseAddress);
            emit WeddingInvalidated(engagement.spouse2.spouseAddress);
        }
    }


    // GETTERS FOR DEBUG
    function getGuestList(address _spouse) external view returns (address[] memory) {
        address guestListKey = getGuestListKey(_spouse);
        return guestLists[guestListKey].proposedGuests;
    }


    function getEngagementInfo(address _spouse) external view returns (address, address, uint256, bool, bool) {
        Engagement memory engagement = engagements[_spouse];
        return (
            engagement.spouse1.spouseAddress,
            engagement.spouse2.spouseAddress,
            engagement.weddingDate,
            engagement.isRevoked,
            engagement.spouse1.isEngaged && engagement.spouse2.isEngaged
        );
    }


    // NFT Functions
    function voteBurn() public {
        Engagement storage engagement = engagements[msg.sender];
        require(
            msg.sender == engagement.spouse1.spouseAddress || 
            msg.sender == authorisedAccount || 
            msg.sender == engagement.spouse2.spouseAddress,
            "Not authorized"
        );
        engagement.burnCertificate += 1;
    }
    
    function burnCertificate(uint256 tokenId) external {
        require(engagements[msg.sender].burnCertificate > 1, "Not authorized");
        _burn(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721, ERC721)  {
        revert("Wedding certificate transfer are not authorized");
    }
}