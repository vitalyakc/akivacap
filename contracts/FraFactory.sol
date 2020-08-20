pragma solidity 0.5.12;

import "./config/Config.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAgreement.sol";
import "./helpers/Administrable.sol";
import "../node_modules/zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol";

/**
 * @title   Fra Factory
 * @dev     Handler of all agreements
 */
contract FraFactory is Administrable {
    address[] public agreementList;
    address payable public agreementImpl;
    address public configAddr;

    /**
     * @dev Set config and agreement implementation
     * @param _agreementImpl address of agreement implementation contract
     * @param _configAddr address of config contract
     */
    constructor(address payable _agreementImpl, address _configAddr) public {
        setConfigAddr(_configAddr);
        setAgreementImpl(_agreementImpl);
    }

    /**
     * @dev Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32 - only ETH
     * @return agreement address
     */
    function initAgreementETH (
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) external payable returns(address _newAgreement) {
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        IAgreement(agreementProxyAddr).
            initAgreement.value(msg.value)(msg.sender, msg.value, _debtValue, _duration, _interestRate, _collateralType, true, configAddr);
        
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr; //address(agreement);
    }

    /**
     * @dev Requests agreement on ERC-20 collateralType
     * @param _debtValue value of borrower's collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY 
     * @param _collateralType type of collateral, should be passed as bytes32
     * @return agreement address
     */
    function initAgreementERC20 (
        uint256 _collateralValue,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType
    ) external returns(address _newAgreement) {

        address  agreementProxyAddr;
        agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        
        IAgreement(agreementProxyAddr).
            initAgreement(msg.sender, _collateralValue, _debtValue, _duration, _interestRate, _collateralType, false, configAddr);
        
        IERC20 t = IAgreement(agreementProxyAddr).erc20TokenContract(_collateralType);        
        t.transferFrom(msg.sender, address(agreementProxyAddr), _collateralValue);
        
        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    /**
     * @dev Set the new agreement implememntation adresss
     * @param _agreementImpl address of agreement implementation contract
     */
    function setAgreementImpl(address payable _agreementImpl) public onlyAdmin() {
        require(_agreementImpl != address(0), "FraFactory: agreement impl address should not be zero");
        agreementImpl = _agreementImpl;
    }

    /**
     * @dev Set the new config adresss
     * @param _configAddr address of config contract
     */
    function setConfigAddr(address _configAddr) public onlyAdmin() {
        require(_configAddr != address(0), "FraFactory: agreement impl address should not be zero");
        configAddr = _configAddr;
    }

    /**
     * @dev Makes the specific agreement valid
     * @param _address agreement address
     * @return operation success
     */
    function approveAgreement(address _address) public onlyAdmin() returns(bool _success) {
        return IAgreement(_address).approveAgreement();
    }

    /**
    * @dev Multi approve
    * @param _addresses agreements addresses array
    */
    function batchApproveAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isStatus(IAgreement.Statuses.Pending)) {
                IAgreement(_addresses[i]).approveAgreement();
            }
        }
    }

    /**
     * @dev Reject specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function rejectAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).rejectAgreement();
    }

    /**
    * @dev Multi reject
    * @param _addresses agreements addresses array
    */
    function batchRejectAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isBeforeStatus(IAgreement.Statuses.Active)) {
                IAgreement(_addresses[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Function for cron autoreject (close agreements if matchLimit expired)
     */
    function autoRejectAgreements() external onlyAdmin() {
        uint _approveLimit = Config(configAddr).approveLimit();
        uint _matchLimit = Config(configAddr).matchLimit();
        uint _len = agreementList.length;
        for (uint256 i = 0; i < _len; i++) {
            if (
                IAgreement(agreementList[i]).isBeforeStatus(IAgreement.Statuses.Active) &&
                IAgreement(agreementList[i]).checkTimeToCancel(_approveLimit, _matchLimit)
            ) {
                IAgreement(agreementList[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Update the state of specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function updateAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).updateAgreement();
    }

    /**
     * @dev Update the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() external onlyAdmin() {
        for (uint256 i = 0; i < agreementList.length; i++) {
            if (IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Active)) {
                IAgreement(agreementList[i]).updateAgreement();
            }
        }
    }

    /**
    * @dev Update state of exact agreements
    * @param _addresses agreements addresses array
    */
    function batchUpdateAgreements(address[] calldata _addresses) external onlyAdmin() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            // check in order to prevent revert
            if (IAgreement(_addresses[i]).isStatus(IAgreement.Statuses.Active)) {
                IAgreement(_addresses[i]).updateAgreement();
            }
        }
    }

    /**
     * @dev Block specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function blockAgreement(address _address) external onlyAdmin() returns(bool _success) {
        return IAgreement(_address).blockAgreement();
    }

    /**
     * @dev Remove agreement from list,
     * doesn't affect real agreement contract, just removes handle control
     */
    function removeAgreement(uint _ind) external onlyAdmin() {
        agreementList[_ind] = agreementList[agreementList.length-1];
        agreementList.length--; // Implicitly recovers gas from last element storage
    }

    /**
     * @dev transfer agreement ownership to Fra Factory owner (admin)
     */
    function transferAgreementOwnership(address _address) external onlyAdmin() {
        IAgreement(_address).transferOwnership(owner);
    }

    /**
     * @dev accept agreement ownership by Fra Factory contract
     */
    function claimAgreementOwnership(address _address) external onlyAdmin() {
        IAgreement(_address).claimOwnership();
    }

    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() external view returns(address[] memory _agreementList) {
        return agreementList;
    }
}
