pragma solidity 0.5.11;

import "./config/Config.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAgreement.sol";
import "./helpers/Claimable.sol";
import "zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol";

/**
 * @title Fra Factory
 * @notice Handler of all agreements
 */
contract FraFactory is Claimable {
    mapping(address => bool) public isAgreement;
    address[] public agreementList;
    address payable public agreementImpl;
    address public configAddr;

    /**
     * @notice Set config and agreement implementation
     * @param _agreementImpl address of agreement implementation contract
     * @param _configAddr address of config contract
     */
    constructor(address payable _agreementImpl, address _configAddr) public {
        super.initialize();
        setConfigAddr(_configAddr);
        setAgreementImpl(_agreementImpl);
    }

    /**
     * @notice Requests agreement on ETH collateralType
     * @param _debtValue value of borrower's ETH put into the contract as collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like RAY
     * @param _collateralType type of collateral, should be passed as bytes32
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
     * @notice Requests agreement on ERC-20 collateralType
     * @param _debtValue value of borrower's collateral
     * @param _duration number of minutes which agreement should be terminated after
     * @param _interestRate percent of interest rate, should be passed like
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
        address payable agreementProxyAddr = address(new UpgradeabilityProxy(agreementImpl, ""));
        IAgreement(agreementProxyAddr).
            initAgreement(msg.sender, _collateralValue, _debtValue, _duration, _interestRate, _collateralType, false, configAddr);

        IAgreement(agreementProxyAddr).erc20TokenContract(_collateralType).transferFrom(
            msg.sender, address(agreementProxyAddr), _collateralValue);

        agreementList.push(agreementProxyAddr);
        return agreementProxyAddr;
    }

    /**
     * @notice Set the new agreement implememntation adresss
     * @param _agreementImpl address of agreement implementation contract
     */
    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        require(_agreementImpl != address(0), "FraFactory: agreement impl address should not be zero");
        agreementImpl = _agreementImpl;
    }

    /**
     * @notice Set the new config adresss
     * @param _configAddr address of config contract
     */
    function setConfigAddr(address _configAddr) public onlyContractOwner() {
        require(_configAddr != address(0), "FraFactory: agreement impl address should not be zero");
        configAddr = _configAddr;
    }

    /**
     * @notice Makes the specific agreement valid
     * @param _address agreement address
     * @return operation success
     */
    function approveAgreement(address _address) public onlyContractOwner returns(bool _success) {
        return IAgreement(_address).approveAgreement();
    }

    /**
    * @notice Multi approve
    * @param _addresses agreements addresses array
    */
    function batchApproveAgreements(address[] memory _addresses) public onlyContractOwner {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isPending()) {
                IAgreement(_addresses[i]).approveAgreement();
            }
        }
    }

    /**
     * @notice Reject specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function rejectAgreement(address _address) public onlyContractOwner returns(bool _success) {
        return IAgreement(_address).rejectAgreement();
    }

    /**
    * @notice Multi reject
    * @param _addresses agreements addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public onlyContractOwner {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (IAgreement(_addresses[i]).isBeforeMatched()) {
                IAgreement(_addresses[i]).rejectAgreement();
            }
        }
    }

    /**
     * @notice Function for cron autoreject (close agreements if matchLimit expired)
     */
    function autoRejectAgreements() public onlyContractOwner {
        uint _approveLimit = Config(configAddr).approveLimit();
        uint _matchLimit = Config(configAddr).matchLimit();
        uint _len = agreementList.length;
        for (uint256 i = 0; i < _len; i++) {
            if (IAgreement(agreementList[i]).isBeforeMatched() && IAgreement(agreementList[i]).checkTimeToCancel(_approveLimit, _matchLimit)) {
                IAgreement(agreementList[i]).rejectAgreement();
            }
        }
    }

    /**
     * @notice Update the state of specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function updateAgreement(address _address) public onlyContractOwner returns(bool _success) {
        return IAgreement(_address).updateAgreement();
    }

    /**
     * @notice Update the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() public onlyContractOwner {
        for (uint256 i = 0; i < agreementList.length; i++) {
            if (IAgreement(agreementList[i]).isActive()) {
                IAgreement(agreementList[i]).updateAgreement();
            }
        }
    }

    /**
    * @notice Update state of exact agreements
    * @param _addresses agreements addresses array
    */
    function batchUpdateAgreements(address[] memory _addresses) public onlyContractOwner {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            // check in order to prevent revert
            if (IAgreement(_addresses[i]).isActive()) {
                IAgreement(_addresses[i]).updateAgreement();
            }
        }
    }

    /**
     * @notice Block specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function blockAgreement(address _address) public onlyContractOwner returns(bool _success) {
        return IAgreement(_address).blockAgreement();
    }

    /**
     * @notice Remove agreement from list,
     * doesn't affect real agreement contract, just removes handle control
     */
    function removeAgreement(uint _ind) public onlyContractOwner {
        agreementList[_ind] = agreementList[agreementList.length-1];
        agreementList.length--; // Implicitly recovers gas from last element storage
    }

    /**
     * @notice transfer agreement ownership to Fra Factory owner (admin)
     */
    function transferAgreementOwnership(address _address) public onlyContractOwner {
        IAgreement(_address).transferOwnership(owner);
    }
    
    /**
     * @notice Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
}
