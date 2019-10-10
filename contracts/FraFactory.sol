pragma solidity 0.5.11;

import './interfaces/ERC20Interface.sol';
import './interfaces/AgreementInterface.sol';
import './helpers/Claimable.sol';
import 'zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol';


/**
 * @title Handler of all agreements
 */
contract FraFactory is Initializable, Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;
    address payable agreementImpl;

    function initialize(address payable _agreementImpl) public initializer {
        Ownable.initialize();
        setAgreementImpl(_agreementImpl);
    }

    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        agreementImpl = _agreementImpl;
    }
    /**
     * @dev Requests egreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _durationMins number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function requestAgreementOnETH (
        uint256 _debtValue, uint256 _durationMins,
        uint256 _interestRate, bytes32 _collateralType)
    public payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initialize.value(msg.value)(msg.sender, msg.value, _debtValue, _durationMins, _interestRate, _collateralType);

        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's collateral
     * @param _durationMins number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like (some % * 10^25)
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function requestAgreementOnERC20 (
        uint256 _collateralValue,uint256 _debtValue,
        uint256 _durationMins, uint256 _interestRate,
        bytes32 _collateralType)
    public payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        AgreementInterface(agreementProxyAddr).
            initialize(msg.sender, _collateralValue, _debtValue, _durationMins, _interestRate, _collateralType);

        AgreementInterface(agreementProxyAddr).erc20TokenContract(_collateralType).transferFrom(
            msg.sender, address(agreementProxyAddr), _collateralValue);

        agreements[msg.sender].push(agreementProxyAddr);
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    /**
     * @dev Updates the states of all agreemnets
     * @return operation success
     */
    function checkAllAgreements() public onlyContractOwner() returns(bool _success) {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (!AgreementInterface(agreementList[i]).isClosed()) {
                AgreementInterface(agreementList[i]).checkAgreement();
            }
        }
        return true;
    }

    /**
    * @dev Multi reject
    * @param _addresses addresses array
    */
    function batchCheckAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!AgreementInterface(_addresses[i]).isClosed()) {
                AgreementInterface(_addresses[i]).checkAgreement();
            } else {
                continue;
            }
        }
    }

    /**
     * @dev Updates the state of specific agreement
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
        return AgreementInterface(_agreement).approveAgreement();
    }

    /**
     * @dev Reject specific agreement
     * @return operation success
     */
    function rejectAgreement(address _agreement) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_agreement).cancelAgreement();
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
    * @dev Multi reject
    * @param _addresses addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            rejectAgreement(_addresses[i]);
        }
    }
}
