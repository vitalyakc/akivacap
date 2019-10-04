pragma solidity 0.5.11;

/**
 * @title Interface for Agreement contract
 */
contract Config {

    uint public approveLimitHours; // max duration available for approve after creation, if expires - agreement should be closed
    uint public matchLimitHours; // max duration available for match after approve, if expires - agreement should be closed
    uint public injectionThreshold;
    uint public minCollateralAmount;
    uint public maxCollateralAmount;
    
    /**
     * @dev     Get collateral addresses according to release
     * @param   _injectionThreshold     minimal threshold permitted for injection
     * @param   _minCollateralAmount    min amount in wei for ether or in minimal units for other erc-20 tokens
     * @param   _maxCollateralAmount    max amount in wei for ether or in minimal units for other erc-20 tokens
     * @return  _mcdJoinContract  address of token adapter
     * @return  _baseContract   basic token contract (or wrapper in case of ETH)
     */
    constructor(uint _matchLimitHours, uint _injectionThreshold, uint _minCollateralAmount, uint _maxCollateralAmount) public CollateralConfig() {
        matchLimitHours = _matchLimitHours;
        injectionThreshold = _injectionThreshold;
        minCollateralAmount = _minCollateralAmount;
        maxCollateralAmount = _maxCollateralAmount;
    }




    // /**
    //  * @dev     Get current cdp main info: collateral amount, dai (debt) amount
    //  * @param   ilk     collateral type in bytes32 format
    //  * @param   cdpId   cdp ID
    //  * @return  ink     collateral tokens amount
    //  *          art     dai debt amount
    //  */
    // function getCdpInfo(bytes32 ilk, uint cdpId) public view returns(uint ink, uint art) {
    //     address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
    //     (ink, art) = VatLike(mcdVatAddr).urns(ilk, urn);
    // }

    //     /**
    //  * @dev     get amount of dai tokens currently locked in dsr(pot) contract.
    //  * @return  pie amount of all dai tokens locked in dsr
    //  */
    // function getLockedDai() public view returns(uint256) {
    //     return PotLike(mcdPotAddr).pie(address(proxy()));
    // }
    
    // /**
    //  * @dev     get dai savings rate
    //  * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
    //  */
    // function getDsr() public view returns(uint) {
    //     return PotLike(mcdPotAddr).dsr();
    // }
}