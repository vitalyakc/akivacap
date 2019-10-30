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
    constructor() public {
    }

    function getAgreements(address _fraFactoryAddr, uint _status, address _user) public view returns(address[] memory agreementsSorted) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
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

    function getAgreementsCount(address _fraFactoryAddr) public view returns(uint cntOpen, uint cntActive, uint cntEnded) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();

        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isOpen()) {
                cntOpen++;
            }
            if (AgreementInterface(agreementList[i]).isActive()) {
                cntActive++;
            }
            if (AgreementInterface(agreementList[i]).isEnded()) {
                cntEnded++;
            }
        }
    }

    function getActiveCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive()) {
                cdpIds[cntSorted] = AgreementInterface(agreementList[i]).cdpId();
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(cdpIds, sub(mload(cdpIds), cntDelete)) }
    }

    function getTotalCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive() || AgreementInterface(agreementList[i]).isOpen() || AgreementInterface(agreementList[i]).isEnded()) {
                cdpIds[cntSorted] = AgreementInterface(agreementList[i]).cdpId();
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(cdpIds, sub(mload(cdpIds), cntDelete)) }
    }
}