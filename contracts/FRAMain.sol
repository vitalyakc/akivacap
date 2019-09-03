pragma solidity 0.5.11;

import './DaiInterface.sol';
import './Claimable.sol';
import './Agreement.sol';


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
        uint256 length = activeAgreementList.length;
        for(uint256 i = 0; i < length; i++) {
            if (AgreementInterface(activeAgreementList[i]).isClosed()) {
                activeAgreementList[i] = activeAgreementList[length - 1];
                delete activeAgreementList[length - 1];
                length--;
                i--;
                continue;
            } else {
                AgreementInterface(activeAgreementList[i]).checkAgreement();
            }
        }
        activeAgreementList.length = length;
    }
    
    function getNow () public view returns(uint256) { // for testing
        return now;
    }
}
