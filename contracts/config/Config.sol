pragma solidity 0.5.12;

import "../helpers/ClaimableBase.sol";
import "../helpers/RaySupport.sol";

/**
 * @title Config for Agreement contract
 */
contract Config is ClaimableBase, RaySupport {
    mapping(bytes32 => bool) public collateralsEnabled;

    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;
    uint public minDuration;
    uint public maxDuration;
    uint public riskyMargin;
    uint public acapFee;   // per second %
    address payable public acapAddr;  // 

    /**
     * @dev     Set default config
     */
    constructor() public {
        // last parameter: fee is 0.5% annual in per-second compounding 
        setGeneral(7 days, 1 days, 0.01 ether, 0.2 ether, 10000 ether, 1 minutes, 1000 days, 20);
        enableCollateral("ETH-A");
        enableCollateral("BAT-A");
        enableCollateral("WBTC-A");
        enableCollateral("USDC-A");
        enableCollateral("USDC-B");
        acapFee  = 1000000000158153903837946257;
        acapAddr = 0xF79179D06C687342a3f5C1daE5A7253AFC03C7A8;  

    }

    /**
     * @dev     Set all config parameters
     * @param   _approveLimit      max time available for approve after creation, if expires - agreement should be closed
     * @param   _matchLimit        max time available for match after approve, if expires - agreement should be closed
     * @param   _injectionThreshold     minimal threshold permitted for injection
     * @param   _minCollateralAmount    min amount
     * @param   _maxCollateralAmount    max amount
     * @param   _minDuration        min agreement length
     * @param   _maxDuration        max agreement length
     * @param   _riskyMargin        risky Margin %
     */
    function setGeneral(
        uint _approveLimit,
        uint _matchLimit,
        uint _injectionThreshold,
        uint _minCollateralAmount,
        uint _maxCollateralAmount,
        uint _minDuration,
        uint _maxDuration,
        uint _riskyMargin
    ) public onlyContractOwner {
        approveLimit = _approveLimit;
        matchLimit = _matchLimit;
        
        injectionThreshold = _injectionThreshold;
        
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;

        minDuration = _minDuration;
        maxDuration = _maxDuration;

        riskyMargin = _riskyMargin;
    }

    /**
     * @dev     Set config parameter
     * @param   _acapFee  fee in % per second
     */
    function setAcapFee(uint _acapFee) public onlyContractOwner {
        acapFee = _acapFee;
    }

    /**
     * @dev     Set config parameter
     * @param   _a  address for fees
     */
    function setAcapAddr(address payable _a) public onlyContractOwner {
        acapAddr = _a;
    }


    /**
     * @dev     Set config parameter
     * @param   _riskyMargin        risky Margin %
     */
    function setRiskyMargin(uint _riskyMargin) public onlyContractOwner {
        riskyMargin = _riskyMargin;
    }

    /**
     * @dev     Set config parameter
     * @param   _approveLimit        max duration available for approve after creation, if expires - agreement should be closed
     */
    function setApproveLimit(uint _approveLimit) public onlyContractOwner {
        approveLimit = _approveLimit;
    }

    /**
     * @dev     Set config parameter
     * @param   _matchLimit        max duration available for match after approve, if expires - agreement should be closed
     */
    function setMatchLimit(uint _matchLimit) public onlyContractOwner {
        matchLimit = _matchLimit;
    }

    /**
     * @dev     Set config parameter
     * @param   _injectionThreshold     minimal threshold permitted for injection
     */
    function setInjectionThreshold(uint _injectionThreshold) public onlyContractOwner {
        injectionThreshold = _injectionThreshold;
    }

    /**
     * @dev     Enable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function enableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = true;
    }

    /**
     * @dev     Disable colateral type
     * @param   _ilk     bytes32 collateral type
     */
    function disableCollateral(bytes32 _ilk) public onlyContractOwner {
        collateralsEnabled[_ilk] = false;
    }

    /**
     * @dev     Check if colateral is enabled
     * @param   _ilk     bytes32 collateral type
     */
    function isCollateralEnabled(bytes32 _ilk) public view returns(bool) {
        return collateralsEnabled[_ilk];
    }
}