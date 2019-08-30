pragma solidity 0.5.11;

import "./Claimable.sol";
import "./Agreement.sol";


contract FRAMain is Claimable {
    mapping(address => address[]) public agreements;
    address[] fullAgreementList;
    address[] activeAgreementList;
    
    function requestAgreementOnETH (uint256 _expairyDate, uint256 _debtValue, uint256 _interestRate) 
    public payable returns(address _newAgreement) {
        
        AgreementETH agreement = new AgreementETH(msg.sender, msg.value, _debtValue, _expairyDate, _interestRate);
        agreements[msg.sender].push(address(agreement));
        fullAgreementList.push(address(agreement));
        activeAgreementList.push(address(agreement));
        return address(agreement);
    }
    
    function checkAllAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < activeAgreementList.length; i++) {
            if (AgreementInterface(activeAgreementList[i]).isClosed()) {
                activeAgreementList[i] = activeAgreementList[activeAgreementList.length - 1];
                delete activeAgreementList[activeAgreementList.length - 1];
                activeAgreementList.length -= 1;
            } else {
                AgreementInterface(activeAgreementList[i]).checkAgreement();
            }
        }
    }
    
    function getNow () public view returns(uint256) { // for testing
        return now;
    }
}





