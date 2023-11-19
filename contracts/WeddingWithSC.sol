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
        uint256 votingPeriodStart;
        bool isVotingPeriod;
    }

    // Decided to just have address and bools in Spouse struct
    // because we did not want to save anything other than their 
    // address, as we see this as their ID. 
    struct Spouse {
        address spouseAddress;
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
    event MarriageProposed(address proposer);
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
        Engagement memory engagement = engagements[getPrimarySpouseAddress(_spouseAddress)];
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
        require(engagements[getPrimarySpouseAddress(_spouse)].isRevoked == false, "The engagement is already revoked.");
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

    modifier isGuestListConfirmed(address _spouse) {
        address guestListKey = getGuestListKey(_spouse);
        GuestList storage guestList = guestLists[guestListKey];
        require(guestList.spouse1Confirmed && guestList.spouse2Confirmed, "Guest list must be confirmed by both spouses first");
        _;
    }

    // TODO: Modifiers for date, musst be fixed as solidity is weird.
    modifier futureDate(uint256 _date) {
        require(_date > block.timestamp, "Date must be in the future");
        _;
    }

    modifier isBeforeWeddingDate(address _spouse) {
        Engagement memory engagement = engagements[getPrimarySpouseAddress(_spouse)];
        require(block.timestamp < engagement.weddingDate - 1 days, "The wedding date is already here");
        _;
    }

    modifier weddingDateHasArrived(address _spouse) {
        require(block.timestamp >= engagements[getPrimarySpouseAddress(_spouse)].weddingDate, "Wedding date not yet arrived");
        _;
    }

    modifier weddingDateHasNotPassed(address _spouse) {
        require(block.timestamp < engagements[getPrimarySpouseAddress(_spouse)].weddingDate + 1 days, "Wedding date passed");
        _;
    }

    modifier withinVotingPeriod(address _spouse) {
        Engagement memory engagement = engagements[getPrimarySpouseAddress(_spouse)];
        require(engagement.isVotingPeriod && (block.timestamp <= engagement.votingPeriodStart + 60 seconds), "Voting period is not active");
        _;
    }

    modifier canConfirmMarriage(address _spouse) {
        Engagement memory engagement = engagements[getPrimarySpouseAddress(_spouse)];
        require(!engagement.isRevoked, "Marriage revoked due to voting");
        require(engagement.isVotingPeriod == false, "Guests can still vote against the wedding");
        _;
    }

    constructor() ERC721("EngagementRegistry", "ENR"){
        // add an authorized account
        authorisedAccount = (0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C);
    }

//ENGAGEMENT (TASK 1)

    // Registers an engagement between the caller (proposer) and the proposee.
    // The function takes the address of the proposee and the proposed wedding date as parameters.
        function registerEngagement(address _proposeeAddress, uint256 _weddingDate) external 
        notSameAddress(_proposeeAddress)
        notEngaged(_proposeeAddress)
    {
        // Create Spouse structs for the proposer and proposee and set their engagement status.
        spouses[msg.sender] = Spouse({spouseAddress: msg.sender, isEngaged: true, isMarried: false});
        spouses[_proposeeAddress] = Spouse({spouseAddress: _proposeeAddress, isEngaged: true, isMarried: false});

        // Create an Engagement struct and assign it to both spouses.
        Engagement memory newEngagement = Engagement({
            spouse1: spouses[msg.sender],
            spouse2: spouses[_proposeeAddress],
            weddingDate: _weddingDate,
            isRevoked: false,
            spouse1ConfirmedMarriage: false,
            spouse2ConfirmedMarriage: false,
            burnCertificate: 0,
            votingPeriodStart: 0,
            isVotingPeriod: false
        });

        engagements[msg.sender] = newEngagement;
        engagements[_proposeeAddress] = newEngagement;

        // Emit an event indicating the engagement registration.
        emit EngagementRegistered(msg.sender, _proposeeAddress, _weddingDate);
    }



// PARTICIPATION (TASK 2)

    // Allows an engaged party to propose a guest list for their wedding.
    function proposeGuestList(address[] calldata _guests) public isEngagedParty(msg.sender) isNotMarried(msg.sender){
        // Retrieve the key to access the correct guest list.
        address guestListKey = getGuestListKey(msg.sender);

        // Access the guest list using the key.
        GuestList storage guestList = guestLists[guestListKey];

        // Set the proposed guests and reset confirmation flags.
        guestList.proposedGuests = _guests;
        guestList.spouse1Confirmed = false;
        guestList.spouse2Confirmed = false;

        // Emit an event indicating a new guest list has been proposed.
        emit GuestListProposed(msg.sender, _guests);
    }

    // Allows an engaged party to confirm the proposed guest list.
    function confirmGuestList() public isEngagedParty(msg.sender) {
        // Retrieve the key to access the correct guest list.
        address guestListKey = getGuestListKey(msg.sender);

        // Access the guest list using the key.
        GuestList storage guestList = guestLists[guestListKey];

        // Confirm the guest list based on who is calling the function.
        if (msg.sender == engagements[msg.sender].spouse1.spouseAddress) {
            guestList.spouse1Confirmed = true;
        } else {
            guestList.spouse2Confirmed = true;
        }

        // Emit an event if both spouses have confirmed the guest list.
        if (guestList.spouse1Confirmed && guestList.spouse2Confirmed) {
            emit GuestListConfirmed(msg.sender);
        }
    }

    // Internal function to get the key for accessing the guest list in the mapping.
    // The key is the address of spouse1 in the engagement.
    function getGuestListKey(address _spouse) internal view returns (address) {
        Engagement memory engagement = engagements[_spouse];
        return engagement.spouse1.spouseAddress;
    }


    // Checks if a particular guest is confirmed for the wedding of a given spouse.
    function isGuestConfirmed(address _spouse, address _guest) internal view returns (bool) {
        // Retrieve the key to access the correct guest list.
        address guestListKey = getGuestListKey(_spouse);

        // Access the guest list using the key.
        GuestList storage guestList = guestLists[guestListKey];

        // Check if both spouses have confirmed the guest list.
        if (guestList.spouse1Confirmed && guestList.spouse2Confirmed) {
            // Iterate through the proposed guests to find the guest in question.
            for (uint8 i = 0; i < guestList.proposedGuests.length; i++) {
                if (guestList.proposedGuests[i] == _guest) {
                    return true; // Guest is confirmed.
                }
            }
        }
        return false; // Guest is not confirmed or the list is not yet confirmed by both.
    }


// REVOKE ENGAGEMENT (PART 3)

    // Allows an engaged party to revoke their engagement.
    function revokeEngagement() public isNotRevoked(msg.sender) isEngagedParty(msg.sender) {
        // Retrieve the engagement details.
        Engagement storage engagement = engagements[msg.sender];

        // Delete the engagement records for both spouses.
        delete engagements[engagement.spouse1.spouseAddress];
        delete engagements[engagement.spouse2.spouseAddress];

        // Update the engagement status in the Spouse structs.
        spouses[engagement.spouse1.spouseAddress].isEngaged = false;
        spouses[engagement.spouse2.spouseAddress].isEngaged = false;

        // Emit an event indicating the engagement has been revoked.
        emit EngagementRevoked(msg.sender, block.timestamp);
    }


// MARRY (PART 4)

    // Allows an engaged party to propose marriage.
    function proposeMarriage() public 
        isEngagedParty(msg.sender)
        isNotRevoked(msg.sender)
        isNotMarried(msg.sender)
        isGuestListConfirmed(msg.sender)
    {
        // Retrieve the engagement details.
        Engagement storage engagement = engagements[getPrimarySpouseAddress(msg.sender)];

        // Set the marriage confirmation status for the caller.
        if (msg.sender == engagement.spouse1.spouseAddress) {
            engagement.spouse1ConfirmedMarriage = true;
        } else if (msg.sender == engagement.spouse2.spouseAddress) {
            engagement.spouse2ConfirmedMarriage = true;
        }

        // Emit an event indicating that a marriage proposal has been made.
        startVotingPeriod(msg.sender);
        emit MarriageProposed(msg.sender);
    }

    // Allows the other engaged party to confirm the marriage proposal.
    function confirmMarriage() public 
        isEngagedParty(msg.sender)
        isNotMarried(msg.sender)
        canConfirmMarriage(msg.sender)
    {
        // Retrieve the engagement details.
        Engagement storage engagement = engagements[getPrimarySpouseAddress(msg.sender)];

        // Confirm the marriage based on who is calling the function.
        if (msg.sender == engagement.spouse1.spouseAddress) {
            require(!engagement.spouse1ConfirmedMarriage, "Already confirmed");
            engagement.spouse1ConfirmedMarriage = true;
        } else if (msg.sender == engagement.spouse2.spouseAddress) {
            require(!engagement.spouse2ConfirmedMarriage, "Already confirmed");
            engagement.spouse2ConfirmedMarriage = true;
        }

        // Finalize the marriage if both spouses have confirmed.
        if (engagement.spouse1ConfirmedMarriage && engagement.spouse2ConfirmedMarriage) {
            finalizeMarriage(engagement);
        }
    }

    // Internal function to finalize the marriage process.
    function finalizeMarriage(Engagement storage engagement) internal {
        // Update the married status in the Spouse structs for both spouses.
        spouses[engagement.spouse1.spouseAddress].isMarried = true;
        spouses[engagement.spouse2.spouseAddress].isMarried = true;

        // Emit an event indicating the marriage is confirmed.
        emit MarriageConfirmed(engagement.spouse1.spouseAddress, engagement.spouse2.spouseAddress);

        // Minting tokens representing the marriage for both spouses.
        _safeMint(engagement.spouse1.spouseAddress, totalSupply() + 1);
        _safeMint(engagement.spouse2.spouseAddress, totalSupply() + 1);
    }

    // Utility function to always retrieve the primary spouse's address for consistent mapping access
    function getPrimarySpouseAddress(address spouse) internal view returns (address) {
        Engagement memory engagement = engagements[spouse];
        return engagement.spouse1.spouseAddress;
    }


// VOTING (PART 5)

    // // Function to start the voting period
    function startVotingPeriod(address _spouse) internal isEngagedParty(_spouse) {
        Engagement storage engagement = engagements[getPrimarySpouseAddress(_spouse)];
        // start at current time, modifier ensures 60 second must have passed before spouse can confirm marriage. 
        engagement.votingPeriodStart = block.timestamp;
        engagement.isVotingPeriod = true;
    }

    // Allows a confirmed guest to vote against the wedding of an engaged couple.
    function voteAgainstWedding(address _spouse) public 
        isNotRevoked(_spouse) 
        isNotMarried(_spouse)
        isEngaged(_spouse)
        isConfirmedGuest(_spouse) // Ensure the caller is a confirmed guest for the wedding.
        hasNotVoted(_spouse) // Ensure the caller has not already voted.
        withinVotingPeriod(_spouse) // Ensure votingPeriod has begun.
    {
        address guestListKey = getGuestListKey(_spouse);

        // Access the guest list using the key.
        GuestList storage guestList = guestLists[guestListKey];

        // Record the vote against the wedding.
        guestList.hasVotedAgainst[msg.sender] = true;
        guestList.votesAgainst++;

        // Emit an event indicating that a guest has voted against the wedding.
        emit GuestVotedAgainst(msg.sender, _spouse);

        // Check if the wedding should be invalidated based on the votes.
        _checkAndInvalidateWedding(_spouse);
    }

    // Internal function to check if the wedding should be invalidated based on votes.
    function _checkAndInvalidateWedding(address _spouse) internal 
    {
        address guestListKey = getGuestListKey(_spouse);
        GuestList storage guestList = guestLists[guestListKey];

        // Retrieve the engagement details.
        Engagement storage engagement = engagements[getPrimarySpouseAddress(_spouse)];

        // Calculate the number of votes required to invalidate the wedding.
        uint256 confirmedGuestCount = guestList.proposedGuests.length;
        uint256 requiredVotesToInvalidate = (confirmedGuestCount + 1) / 2;

        // Check if the number of votes against the wedding meets or exceeds the required threshold.
        if (guestList.votesAgainst >= requiredVotesToInvalidate) {
            // Invalidate the engagement and update the status for both spouses.
            engagement.isRevoked = true;
            spouses[engagement.spouse1.spouseAddress].isEngaged = false;
            spouses[engagement.spouse2.spouseAddress].isEngaged = false;

            // Emit events indicating the wedding has been invalidated.
            emit WeddingInvalidated(engagement.spouse1.spouseAddress);
            emit WeddingInvalidated(engagement.spouse2.spouseAddress);
        }
    }


// GETTERS FOR DEBUG
    function getCurrentTime() public view returns (uint256){
        uint256 currentTime = block.timestamp;
        return currentTime;
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