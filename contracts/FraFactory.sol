pragma solidity 0.5.11;
import './config/Config.sol';
import './interfaces/ERC20Interface.sol';
import './interfaces/AgreementInterface.sol';
import './helpers/Claimable.sol';
import 'zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol';


/**
 * @title Handler of all agreements
 */
contract FraFactory is Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;
    address payable agreementImpl;
    address configAddr;

    constructor(address payable _agreementImpl, address _configAddr) public {
        super.initialize();
        configAddr  = _configAddr;
        setAgreementImpl(_agreementImpl);
    }

    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        agreementImpl = _agreementImpl;
    }
    /**
     * @dev Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementETH (
        uint256 _debtValue, 
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType)
    public payable returns(address _newAgreement) {

        

        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initAgreement.value(msg.value)(msg.sender, msg.value, _debtValue, _duration, _interestRate, _collateralType, true, configAddr);

        
        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementERC20 (
        uint256 _collateralValue,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) public payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initAgreement(msg.sender, _collateralValue, _debtValue, _duration, _interestRate, _collateralType, false, configAddr);

        AgreementInterface(agreementProxyAddr).erc20TokenContract(_collateralType).transferFrom(
            msg.sender, address(agreementProxyAddr), _collateralValue);

        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    

    
    
    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
    
    
    /**
     * @dev Makes the specific agreement valid
     * @return operation success
     */
    function approveAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        if (AgreementInterface(_agreement).isPending()) {
            return AgreementInterface(_agreement).approveAgreement();
        }
        return false;
    }

/**
    * @dev Multi approve
    * @param _addresses addresses array
    */
    function batchApproveAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            approveAgreement(_addresses[i]);
        }
    }


    /**
     * @dev Reject specific agreement
     * @return operation success
     */
    function rejectAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        if (AgreementInterface(_agreement).isBeforeMatched()) {
            return AgreementInterface(_agreement).rejectAgreement();
        }
        return false;
    }

    
    /**
    * @dev Multi reject
    * @param _addresses addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            rejectAgreement(_addresses[i]);
        }
    }

    /**
     * @dev Updates the state of specific agreement
     * @param _agreement address to be updated
     * @return operation success
     */
    function updateAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        if (AgreementInterface(_agreement).isActive()) {
            return AgreementInterface(_agreement).updateAgreement();
        }
        return false;
    }

    /**
     * @dev Updates the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < agreementList.length; i++) {
            updateAgreement(agreementList[i]);
        }
    }

    /**
    * @dev close pending and open agreements with limit expired
    * @param _addresses addresses array
    */
    function batchUpdateAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            updateAgreement(agreementList[i]);
        }
    }
}
