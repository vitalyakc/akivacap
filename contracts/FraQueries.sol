pragma solidity 0.5.11;
import "./interfaces/IAgreement.sol";
import "./helpers/AgreementStatuses.sol";

contract FraFactoryI {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    function getAgreementList() public view returns(address[] memory _agreementList);
}

/**
 * @title Queries for agreements
 */
contract FraQueries is AgreementStatuses {
    constructor() public {
    }

    function getAgreements(address _fraFactoryAddr, uint _status, address _user) public view returns(address[] memory agreementsSorted) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        agreementsSorted = new address[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (
                (_status == 0 || _status > 0 && IAgreement(agreementList[i]).status() == _status) &&
                ((_user == address(0)) || (
                    _user != address(0)) &&
                    ((IAgreement(agreementList[i]).lender() == _user) || (IAgreement(agreementList[i]).borrower() == _user)))
            ) {
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
            if (IAgreement(agreementList[i]).isStatus(Statuses.Open)) {
                cntOpen++;
            }
            if (IAgreement(agreementList[i]).isStatus(Statuses.Active)) {
                cntActive++;
            }
            if (IAgreement(agreementList[i]).isStatus(Statuses.Ended)) {
                cntEnded++;
            }
        }
    }

    function getActiveCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (IAgreement(agreementList[i]).isStatus(Statuses.Active)) {
                cdpIds[cntSorted] = IAgreement(agreementList[i]).cdpId();
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
            if ((IAgreement(agreementList[i]).isStatus(Statuses.Active) ||
                IAgreement(agreementList[i]).isStatus(Statuses.Closed)) && IAgreement(agreementList[i]).cdpId() > 0
            ) {
                cdpIds[cntSorted] = IAgreement(agreementList[i]).cdpId();
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(cdpIds, sub(mload(cdpIds), cntDelete)) }
    }

    function getUsers(address _fraFactoryAddr) public view returns(address[] memory lenders, address[] memory borrowers) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        lenders = new address[](agreementList.length);
        borrowers = new address[](agreementList.length);
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            lenders[i] = IAgreement(agreementList[i]).lender();
            borrowers[i] = IAgreement(agreementList[i]).borrower();
        }
    }
}