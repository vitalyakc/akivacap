
// File: contracts/interfaces/IERC20.sol

pragma solidity 0.5.12;

/**
 * @title Interface for ERC20 token contract
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/IAgreement.sol

pragma solidity 0.5.12;


/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(address payable, uint256, uint256, uint256, uint256, bytes32, bool, address) external payable;

    function transferOwnership(address) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool); // ext
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function matchAgreement() external returns(bool);
    function interestRate() external view returns(uint);
    function duration() external view returns(uint);
    function cdpDebtValue() external view returns(uint);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32); // ext
    function isStatus(Statuses) external view returns(bool);
    function isBeforeStatus(Statuses) external view returns(bool);
    function isClosedWithType(ClosedTypes) external view returns(bool);
    function checkTimeToCancel(uint, uint) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32) external view returns(IERC20);
    function getAssets(address) external view returns(uint,uint); // ext
    function withdrawDai(uint) external;
    function getDaiAddress() external view returns(address); // ext

    function getInfo() external view returns (address,uint,uint,uint,address,address,bytes32,uint,uint,uint,bool); // ext

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int _savingsDifference, int _delta, uint _timeInterval, uint _drawnDai, uint _injectionAmount);
    event AgreementClosed(uint _closedType, address _user);
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 _collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);
    event AdditionalCollateralLocked(uint _amount);
    event RiskyToggled(bool _isRisky);
}

// File: contracts/FraQueries.sol

pragma solidity 0.5.12;


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
                (_status == 0 || _status > 0 && IAgreement(agreementList[i]).status() == _status) &&
                ((_user == address(0)) || (
                    _user != address(0)) &&
                    ((IAgreement(agreementList[i]).lender() == _user) || (IAgreement(agreementList[i]).borrower() == _user)))
            ) {
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
            if (IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Open)) {
                cntOpen++;
            }
            if (IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Active)) {
                cntActive++;
            }
            if (IAgreement(agreementList[i]).isClosedWithType(IAgreement.ClosedTypes.Ended)) {
                cntEnded++;
            }
        }
    }

    function getActiveCdps(address _fraFactoryAddr) public view returns(uint[] memory cdpIds) {
        address[] memory agreementList = FraFactoryI(_fraFactoryAddr).getAgreementList();
        cdpIds = new uint[](agreementList.length);
        uint cntSorted = 0;
        
        for(uint256 i = 0; i < agreementList.length; i++) {
            if (IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Active)) {
                cdpIds[cntSorted] = IAgreement(agreementList[i]).cdpId();
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
            if ((IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Active) ||
                IAgreement(agreementList[i]).isStatus(IAgreement.Statuses.Closed)) && IAgreement(agreementList[i]).cdpId() > 0
            ) {
                cdpIds[cntSorted] = IAgreement(agreementList[i]).cdpId();
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
            lenders[i] = IAgreement(agreementList[i]).lender();
            borrowers[i] = IAgreement(agreementList[i]).borrower();
        }
    }
}
