pragma solidity 0.5.12;

import "./SafeMath.sol";

/**
 * @title   RaySupport contract for ray (10^27) preceision calculations
 */
contract RaySupport {
    using SafeMath for uint256;
    using SafeMath for int256;
    uint constant public ONE  = 10 ** 27;
    uint constant public HALF = ONE / 2;
    uint constant public HUNDRED = 100;

    /**
     * @dev     Convert uint value to Ray format
     * @param   _val    uint value should be converted
     */
    function toRay(uint _val) public pure returns(uint) {
        return _val.mul(ONE);
    }

    /**
     * @dev     Convert uint value from Ray format
     * @param   _val    uint value should be converted
     */
    function fromRay(uint _val) public pure returns(uint) {
        uint x = _val / ONE;
        //if (  (_val.sub(toRay(x))) > uint( (HALF-1) ) )
        //    return x.add(1); 
        return x;
    }

    /**
     * @dev     Convert int value to Ray format
     * @param   _val    int value should be converted
     */
    function toRay(int _val) public pure returns(int) {
        return _val.mul(int(ONE));
    }

    /**
     * @dev     Convert int value from Ray format
     * @param   _val    int value should be converted
     */
    function fromRay(int _val) public pure returns(int) {
        int x = _val / int(ONE);
        //if (  (_val.sub(toRay(x))) > int( (HALF-1) ) )
        //    return x.add(1); 
        return x;
    }

    /**
     * @dev     Calculate x pow n by base
     * @param   x   value should be powered
     * @param   n   power degree
     * @param   base    base value
     */
    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}