pragma solidity 0.5.11;

/**
 * @title Config for Agreement contract
 */
contract Config {
    uint constant YEAR_SECS = 365 days;
    uint public approveLimit; // max duration in secs available for approve after creation, if expires - agreement should be closed
    uint public matchLimit; // max duration in secs available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;

    /**
     * @dev     Set defailt config
     */
    function _initConfig() internal {
        _setConfig(24, 24, 2, 100, 100 ether);
    }

    /**
     * @dev     set sonfig according to parameters
     * @param   _approveLimitHours      max duration available for approve after creation, if expires - agreement should be closed
     * @param   _matchLimitHours        max duration available for match after approve, if expires - agreement should be closed
     * @param   _injectionThreshold     minimal threshold permitted for injection
     * @param   _minCollateralAmount    min amount
     * @param   _maxCollateralAmount    max amount
     */
    function _setConfig(uint _approveLimitHours, uint _matchLimitHours,
        uint _injectionThreshold, uint _minCollateralAmount, uint _maxCollateralAmount) internal {

        approveLimit = _approveLimitHours * 1 hours;
        matchLimit = _matchLimitHours * 1 hours;
        injectionThreshold = _injectionThreshold;
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;
    }

    
}