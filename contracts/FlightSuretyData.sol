pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Airlines
    struct Airline {
        string name;
        bool isAdded;
        bool isRegistered;
        uint256 hasFund;
        uint256 voteCount;
    }

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    address private appContractOwner;
    mapping(address => Airline) private airlines;
    uint256 private airlineCount = 0;
    mapping(bytes32 => address[]) private flights;
    mapping(address => uint256) private insureesBalance;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address airline, string name) public {
        contractOwner = msg.sender;
        _addAirline(airline, name);
        _registerAirline(airline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;
    }

    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAppContractOwner()
    {
        require(msg.sender == appContractOwner, "Caller is not App contract owner");
        _;
    }

    modifier requireisRegisteredAirline(address applicantAirline)
    {
        require(airlines[applicantAirline].isRegistered == true, "Applicant air line is not a isRegistered Airline");
        _;
    }

    modifier requireFundedAirline(address applicantAirline)
    {
        require(airlines[applicantAirline].hasFund >= (10 ether), "Applicant air line has not enough fund");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool)
    {
        return operational;
    }

    function setOperatingStatus (bool mode) external requireContractOwner
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function authorizeCaller(address _appContractOwner) external requireIsOperational requireContractOwner
    {
         appContractOwner = _appContractOwner;
    }

    function addAirline (address hasFundAirline, address airline, string name)
            external payable requireIsOperational requireAppContractOwner
                     requireisRegisteredAirline(hasFundAirline) requireFundedAirline(hasFundAirline)
    {
        _addAirline(airline, name);
    }

    function _addAirline (address airlineAddress, string name) private
    {
        Airline memory airline = Airline(name, true, false, 0, 0);
        airlines[airlineAddress] = airline;
        airlineCount++;
    }

    function registerAirline(address hasFundAirline, address applicantAirline)
            external requireIsOperational requireAppContractOwner
                     requireisRegisteredAirline(hasFundAirline) requireFundedAirline(hasFundAirline)
    {
        _registerAirline(applicantAirline);
    }

    function _registerAirline(address airline) private
    {
        airlines[airline].isRegistered = true;
    }

    function vote(address hasFundAirline, address applicantAirline)
            external requireIsOperational requireAppContractOwner
                     requireisRegisteredAirline(hasFundAirline) requireFundedAirline(hasFundAirline)
    {
        airlines[applicantAirline].voteCount++;
    }

    function fundAirline(address airline, uint256 value) external requireIsOperational requireAppContractOwner
    {
        airlines[airline].hasFund += value;
    }

    function buy(address airline, string flight, uint256 timestamp, address insuree)
            external payable requireIsOperational requireAppContractOwner
    {
        address(this).transfer(msg.value);

        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        flights[flightKey].push(insuree);
    }

    function creditInsurees(address airline, string flight, uint256 timestamp, uint256 value)
            external requireIsOperational requireAppContractOwner
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        for (uint256 i = 0; i < flights[flightKey].length; i++) {
            uint256 currentBalance = insureesBalance[flights[flightKey][i]];
            uint256 newBalance = currentBalance + (value);
            insureesBalance[flights[flightKey][i]] = newBalance;
        }
        delete flights[flightKey];
    }

    function pay(address insuree) external payable requireIsOperational requireAppContractOwner
    {
        require(insureesBalance[insuree] > 0, "This insuree has no balance.");
        uint256 value = insureesBalance[insuree]*15/10;
        insureesBalance[insuree] = 0;
        insuree.transfer(value);
    }

    function getFlightKey (address airline, string memory flight, uint256 timestamp) private pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function getAirline(address addressAirline) external view requireIsOperational requireAppContractOwner
                                                returns(string name, bool isRegistered, uint hasFund, uint voteCount)
    {
        Airline memory airline = airlines[addressAirline];
        return(airline.name, airline.isRegistered, airline.hasFund, airline.voteCount);
    }

    function airlineisAdded(address airline) external view requireIsOperational requireAppContractOwner returns (bool)
    {
        return airlines[airline].isAdded;
    }

    function airlineisRegistered(address airline) external view requireIsOperational requireAppContractOwner returns (bool)
    {
        return airlines[airline].isRegistered;
    }


    function getAirlineVoteCount(address airlineAddress) external view requireIsOperational requireAppContractOwner returns(uint256)
    {
        Airline memory airline = airlines[airlineAddress];
        return(airline.voteCount);
    }

    function getAirlineCount() external view requireIsOperational requireAppContractOwner returns(uint256)
    {
        return airlineCount;
    }

    function getInsureeBalance(address insuree) external view requireIsOperational returns(uint256)
    {
        return insureesBalance[insuree];
    }

    function() external payable
    {
    }

}
