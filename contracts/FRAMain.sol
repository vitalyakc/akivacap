pragma solidity 0.5.11;

import './ERC20Interface.sol';
import './Claimable.sol';
import './Agreement.sol';


/// @title Handler of all agreements
contract FraMain is Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    /**
     * @notice Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral 
     * @param _expairyDate number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
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
    
    /**
     * @notice Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's collateral
     * @param _expairyDate number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function requestAgreementOnERC20 (
        uint256 _collateralValue,uint256 _debtValue, 
        uint256 _expairyDate, uint256 _interestRate, 
        bytes32 _collateralType, address _erc20ContractAddress)
    public payable returns(address _newAgreement) {
        require(_erc20ContractAddress != address(0), 'Contract address has to be not 0x0');
        
        AgreementERC20 agreement = new AgreementERC20(
            msg.sender, _collateralValue, _debtValue, _expairyDate, 
            _interestRate, _collateralType, _erc20ContractAddress);
        
        ERC20Interface(_erc20ContractAddress).transferFrom(
            msg.sender, address(agreement), _collateralValue);
            
        agreements[msg.sender].push(address(agreement));
        agreementList.push(address(agreement));
        return address(agreement);
    }
    
    /**
     * @notice Updates the states of all agreemnets
     * @return operation success
     */
    function checkAllAgreements() public onlyContractOwner() returns(bool _success) {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (!AgreementInterface(agreementList[i]).isClosed()) {
                AgreementInterface(agreementList[i]).checkAgreement();
            } else {
                continue;
            }
        }
        
        return true;
    }

    /**
     * @notice Updates the state of specific agreement
     * @param _agreement address to be updated
     * @return operation success
     */
    function checkAgreement(address _agreement) public onlyContractOwner() returns(bool _success) { 
        if (!AgreementInterface(_agreement).isClosed()) {
            AgreementInterface(_agreement).checkAgreement();
        }
        
        return true;
    }
    
    /**
     * @notice Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
    
    /**
     * @notice Makes the specific agreement valid
     * @return operation success
     */
    function approveAgreement(address _agreement) 
    public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_agreement).approve();
    }
}
