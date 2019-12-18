
// File: contracts\interfaces\IERC20.sol

pragma solidity 0.5.11;

contract IERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts\interfaces\IAgreement.sol

pragma solidity 0.5.11;

/**
 * @title Interface for Agreement contract
 */
interface IAgreement {
    enum Statuses {All, Pending, Open, Active, Closed}
    enum ClosedTypes {Ended, Liquidated, Blocked, Cancelled}

    function initAgreement(
        address payable _borrower,
        uint256 _collateralAmount,
        uint256 _debtValue,
        uint256 _duration,
        uint256 _interestRate,
        bytes32 _collateralType,
        bool _isETH,
        address _configAddr
    ) external payable;

    function transferOwnership(address _newOwner) external;
    function claimOwnership() external;
    function approveAgreement() external returns(bool);
    function updateAgreement() external returns(bool);
    function cancelAgreement() external returns(bool);
    function rejectAgreement() external returns(bool);
    function blockAgreement() external returns(bool);
    function status() external view returns(uint);
    function lender() external view returns(address);
    function borrower() external view returns(address);
    function collateralType() external view returns(bytes32);
    function isStatus(Statuses _status) external view returns(bool);
    function isBeforeStatus(Statuses _status) external view returns(bool);
    function isClosedWithType(ClosedTypes _type) external view returns(bool);
    function checkTimeToCancel(uint _approveLimit, uint _matchLimit) external view returns(bool);
    function cdpId() external view returns(uint);
    function erc20TokenContract(bytes32 ilk) external view returns(IERC20);

    function getInfo()
        external
        view
        returns (
            address _addr,
            uint _status,
            uint _duration,
            address _borrower,
            address _lender,
            bytes32 _collateralType,
            uint _collateralAmount,
            uint _debtValue,
            uint _interestRate,
            bool _isRisky
        );

    event AgreementInitiated(address _borrower, uint _collateralValue, uint _debtValue, uint _expireDate, uint _interestRate);
    event AgreementApproved();
    event AgreementMatched(address _lender, uint _expireDate, uint _cdpId, uint _collateralAmount, uint _debtValue, uint _drawnDai);
    event AgreementUpdated(int savingsDifference, int delta, uint currentDsrAnnual, uint timeInterval, uint drawnDai, uint injectionAmount);
    event AgreementCanceled(address _user);
    event AgreementTerminated();
    event AgreementLiquidated();
    event AgreementBlocked();
    event AssetsCollateralPush(address _holder, uint _amount, bytes32 collateralType);
    event AssetsCollateralPop(address _holder, uint _amount, bytes32 collateralType);
    event AssetsDaiPush(address _holder, uint _amount);
    event AssetsDaiPop(address _holder, uint _amount);
    event CdpOwnershipTransferred(address _borrower, uint _cdpId);

}

// File: contracts\FraQueries.sol

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
