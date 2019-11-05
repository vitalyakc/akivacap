pragma solidity 0.5.11;
import './config/Config.sol';
import './interfaces/ERC20Interface.sol';
import './interfaces/AgreementInterface.sol';
import './helpers/Claimable.sol';
import 'zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol';
// import 'zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol';

/**
 * @title Handler of all agreements
 */
contract FraFactory is Claimable {
    mapping(address => address[]) public agreements;
    address[] public agreementList;
    address payable public agreementImpl;
    address public configAddr;

    constructor(address payable _agreementImpl, address _configAddr) public {
        super.initialize();
        configAddr  = _configAddr;
        setAgreementImpl(_agreementImpl);
    }

    /**
     * @dev Set the new agreement implememntation adresss
     * @param _agreementImpl address of agreement implementation contract
     */
    function setAgreementImpl(address payable _agreementImpl) public onlyContractOwner() {
        require(_agreementImpl != address(0), 'FraFactory: agreement impl address should not be zero');
        agreementImpl = _agreementImpl;
    }

    /**
     * @dev Set the new config adresss
     * @param _configAddr address of config contract
     */
    function setConfigAddr(address _configAddr) public onlyContractOwner() {
        require(_configAddr != address(0), 'FraFactory: agreement impl address should not be zero');
        configAddr = _configAddr;
    }

    /**
     * @dev Requests egreement on ETH collateralType
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
    ) public payable returns(address _newAgreement) {
        // address payable agreementProxyAddr = address(new AdminUpgradeabilityProxy(agreementImpl, owner, ""));
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
     * @dev Makes the specific agreement valid
     * @param _address agreement address
     * @return operation success
     */
    function approveAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).approveAgreement();
    }

    /**
    * @dev Multi approve
    * @param _addresses agreements addresses array
    */
    function batchApproveAgreements(address[] memory _addresses) public onlyContractOwner() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (AgreementInterface(_addresses[i]).isPending()) {
                AgreementInterface(_addresses[i]).approveAgreement();
            }
        }
    }

    /**
     * @dev Reject specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function rejectAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).rejectAgreement();
    }
    
    /**
    * @dev Multi reject
    * @param _addresses agreements addresses array
    */
    function batchRejectAgreements(address[] memory _addresses) public onlyContractOwner() {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (AgreementInterface(_addresses[i]).isBeforeMatched()) {
                AgreementInterface(_addresses[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Function for cron autoreject (close agreements if matchLimit expired)
     */
    function autoRejectAgreements() public onlyContractOwner() {
        uint _approveLimit = Config(configAddr).approveLimit();
        uint _matchLimit = Config(configAddr).matchLimit();
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isBeforeMatched() && AgreementInterface(agreementList[i]).checkTimeToCancel(_approveLimit, _matchLimit)) {
                AgreementInterface(agreementList[i]).rejectAgreement();
            }
        }
    }

    /**
     * @dev Update the state of specific agreement
     * @param _address agreement address
     * @return operation success
     */
    function updateAgreement(address _address) public onlyContractOwner() returns(bool _success) {
        return AgreementInterface(_address).updateAgreement();
    }

    /**
     * @dev Update the states of all agreemnets
     * @return operation success
     */
    function updateAgreements() public onlyContractOwner() {
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive()) {
                AgreementInterface(agreementList[i]).updateAgreement();
            }
        }
    }

    /**
    * @dev Update state of exact agreements
    * @param _addresses agreements addresses array
    */
    function batchUpdateAgreements(address[] memory _addresses) public {
        require(_addresses.length <= 256, "FraMain: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (AgreementInterface(_addresses[i]).isActive()) {
                AgreementInterface(_addresses[i]).updateAgreement();
            }
        }
    }

    /**
     * @dev Returns a full list of existing agreements
     */
    function getAgreementList() public view returns(address[] memory _agreementList) {
        return agreementList;
    }
}
