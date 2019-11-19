
// File: contracts/interfaces/ERC20Interface.sol

pragma solidity 0.5.11;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/AgreementInterface.sol

pragma solidity 0.5.11;


/**
 * @title Interface for Agreement contract
 */
interface AgreementInterface {
    function initAgreement(address payable _borrower, uint256 _collateralAmount,
        uint256 _debtValue, uint256 _duration, uint256 _interestRate, bytes32 _collateralType, bool _isETH, address _configAddr) external payable;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function getInfo() external view returns(address _addr, uint _status, uint _duration, address _borrower, address _lender, bytes32 _collateralType, uint _collateralAmount, uint _debtValue, uint _interestRate);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32);
    function isActive() external view returns(bool);
    function isOpen() external view returns(bool);
    function isEnded() external view returns(bool);
    function isPending() external view returns(bool);
    function isClosed() external view returns(bool);
    function isBeforeMatched() external view returns(bool);
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32 ilk) external view returns(ERC20Interface);

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender);
    event AgreementUpdated(uint _injectionAmount, int _delta, int _deltaCommon, int _savingsDifference);

    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event RefundBase(address lender, uint lenderRefundDai, address borrower, uint cdpId);
    event RefundLiquidated(uint borrowerFraDebtDai, uint lenderRefundCollateral, uint borrowerRefundCollateral);
}

// File: contracts/FraQueries.sol

pragma solidity 0.5.11;


contract FraFactoryI {
    mapping(address => address[]) public agreements;
    address[] public agreementList;

    function getAgreementList() public view returns(address[] memory _agreementList);
}

/**
 * @title Queries for agreements
 */
contract FraQueries {
    constructor() public {
    }

    function getAgreements(address _fraFactoryAddr, uint _status, address _user) public view returns(address[] memory agreementsSorted) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        agreementsSorted = new address[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (
                ((_status == 0) || (_status > 0) && (AgreementInterface(agreementList[i]).status() == _status)) && 
                ((_user == address(0)) || (
                    _user != address(0)) && 
                    ((AgreementInterface(agreementList[i]).lender() == _user) || (AgreementInterface(agreementList[i]).borrower() == _user))))
            {
                agreementsSorted[cntSorted] = agreementList[i];
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(agreementsSorted, sub(mload(agreementsSorted), cntDelete)) }
    }

    function getAgreementsCount(address _fraFactoryAddr) public view returns(uint cntOpen, uint cntActive, uint cntEnded) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();

        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isOpen()) {
                cntOpen++;
            }
            if (AgreementInterface(agreementList[i]).isActive()) {
                cntActive++;
            }
            if (AgreementInterface(agreementList[i]).isEnded()) {
                cntEnded++;
            }
        }
    }

    function getActiveCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive()) {
                cdpIds[cntSorted] = AgreementInterface(agreementList[i]).cdpId();
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(cdpIds, sub(mload(cdpIds), cntDelete)) }
    }

    function getTotalCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (AgreementInterface(agreementList[i]).isActive() || AgreementInterface(agreementList[i]).isOpen() || AgreementInterface(agreementList[i]).isEnded()) {
                cdpIds[cntSorted] = AgreementInterface(agreementList[i]).cdpId();
                cntSorted++;
            }
        }
        uint cntDelete = agreementList.length - cntSorted;
        assembly { mstore(cdpIds, sub(mload(cdpIds), cntDelete)) }
    }

    function getUsers(address _fraFactoryAddr) public view returns(address[] memory lenders, address[] memory borrowers) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        lenders = new address[](agreementList.length);
        borrowers = new address[](agreementList.length);
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            lenders[i] = AgreementInterface(agreementList[i]).lender();
            borrowers[i] = AgreementInterface(agreementList[i]).borrower();
        }
    }
}
