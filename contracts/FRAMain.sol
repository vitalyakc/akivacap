pragma solidity 0.5.11;

import './DaiInterface.sol';
import './Claimable.sol';
import './Agreement.sol';


contract FRAMain is Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    function requestAgreementOnETH (uint256 _debtValue, uint256 _expairyDate, uint256 _interestRate) 
    public payable returns(address _newAgreement) {
        
        AgreementETH agreement = 
            (new AgreementETH).value(msg.value)(msg.sender, msg.value, _debtValue, _expairyDate, _interestRate);
            
        agreements[msg.sender].push(address(agreement));
        agreementList.push(address(agreement));
        return address(agreement);
    }
    
    function checkAllAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < length; i++) {
            if (!AgreementInterface(agreementList[i]).isClosed()) {
                AgreementInterface(agreementList[i]).checkAgreement();
            } else {
                continue;
            }
        }
    }
    
    function getAgreementListLength() public view returns(uint256 _agreementListLength) {
        return agreementList.length;
    }
    
    function getNow () public view returns(uint256) { // for testing
        return now;
    }
}
