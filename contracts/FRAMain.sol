pragma solidity 0.5.11;

import './DaiInterface.sol';
import './Claimable.sol';
import './Agreement.sol';


contract FraMain is Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    function requestAgreementOnETH (
        uint256 _debtValue, uint256 _expairyDate, 
        uint256 _interestRate, bytes32 _collateralType) 
    public payable returns(address _newAgreement) {
        
        AgreementETH agreement = (new AgreementETH).value(msg.value)(
            msg.sender, msg.value, _debtValue, _expairyDate, _interestRate, _collateralType);
            
        agreements[msg.sender].push(address(agreement));
        agreementList.push(address(agreement));
        return address(agreement);
    }
    
    function requestAgreementOnERC20 (uint256 _debtValue, uint256 _expairyDate, 
        uint256 _interestRate, bytes32 _collateralType, address _erc20ContractAddress)
    public payable returns(address _newAgreement) {
        
        AgreementERC20 agreement = (new AgreementERC20).value(msg.value)(
            msg.sender, msg.value, _debtValue, _expairyDate, 
            _interestRate, _collateralType, _erc20ContractAddress);
        
            
        agreements[msg.sender].push(address(agreement));
        agreementList.push(address(agreement));
        return address(agreement);
    }
    
    function checkAllAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (!AgreementInterface(agreementList[i]).isClosed()) {
                AgreementInterface(agreementList[i]).checkAgreement();
            } else {
                continue;
            }
        }
    }

    function checkAgreement(address _agreement) public { //onlyContractOwner()
        if (!AgreementInterface(_agreement).isClosed()) {
            AgreementInterface(_agreement).checkAgreement();
        }
    }
    
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
    
    function approveAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_agreement).approve();
    }
    
    function getNow () public view returns(uint256) { // for testing
        return now;
    }
}
