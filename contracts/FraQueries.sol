pragma solidity 0.5.11;
import './interfaces/AgreementInterface.sol';

contract FraFactoryI {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    function getAgreementList() public view returns(address[] memory _agreementList);
}

/**
 * @title Queries for agreements
 */
contract FraQueries {
    address fraFactoryAddr;
    FraFactoryI fraFactory;
    constructor(address _fraFactoryAddr) public {
        setFraFactory(_fraFactoryAddr);
    }

    function setFraFactory(address _fraFactoryAddr) public {
        fraFactoryAddr = _fraFactoryAddr;
        fraFactory = FraFactoryI(_fraFactoryAddr);
    }

    function getAgreements(uint _status, address _user) public view returns(address[] memory agreementsSorted) {
        address[] memory agreementList = fraFactory.getAgreementList();
        agreementsSorted = new address[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (
                ((_status == 0) || (_status > 0) && (AgreementInterface(agreementList[i]).status() == _status)) && 
                ((_user == address(0)) || (
                    _user != address(0)) && 
                    ((AgreementInterface(agreementList[i]).lender() == _user) || (AgreementInterface(agreementList[i]).borrower() == _user))))
            {
                agreementsSorted[cntSorted] = agreementList[i];
                cntSorted++;
            }
            
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(agreementsSorted, sub(mload(agreementsSorted), cntDelete)) }
    }
        
    function getL() public view returns(uint) {
        address[] memory agreementList = fraFactory.getAgreementList();
        return agreementList.length;
    }
}