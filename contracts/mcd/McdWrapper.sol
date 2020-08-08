pragma solidity 0.5.12;

import "./McdAddressesR17.sol";
import "../interfaces/IMcd.sol";
import "../interfaces/IERC20.sol";
import "../helpers/RaySupport.sol";

/**
 * @title   Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev     delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 17th release mcd cdp.
 */
contract McdWrapper is McdAddressesR17, RaySupport {
    address payable public proxyAddress;

    /**
     * @dev     Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        return DSProxyLike(proxyAddress);
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return  IERC20 instance
     */
    function erc20TokenContract(bytes32 ilk) public view returns(IERC20) {
        (,address payable collateralBaseAddress) = _getCollateralAddreses(ilk);
        return IERC20(collateralBaseAddress);
    }

    /**
     * @dev     get amount of dai tokens currently locked in dsr(pot) contract.
     * @return  pie amount of all dai tokens locked in dsr
     */
    function getLockedDai() public view returns(uint256 pie, uint256 pieS) {
        pie = PotLike(mcdPotAddr).pie(address(proxy()));
        pieS = pie.mul(PotLike(mcdPotAddr).chi());
    }

    /**
     * @dev     get dai savings rate
     * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
     */
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     * @dev     get collateral cost
     * @return  Duty (base rate plus risk premium) in multiplier format, per-second accrual.
     */
    function getIlkDuty(bytes32 _ilkIndex) public view returns (uint) {
        (, uint _duty) = JugLike(mcdJugAddr).ilks(_ilkIndex);
        return _duty;
    }

    /**
     * @dev     Get the equivalent of exact dai amount in terms of collateral type.
     * @dev     Add one more collateral token unit in case if calculated value doesn't cover dai amount
     * @param   ilk         collateral type in bytes32 format
     * @param   daiAmount   dai tokens amount
     * @return  collateral tokens amount worth dai amount
     */
    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
        uint price = getPrice(ilk);
        uint ethAmount = daiAmount.mul(ONE).div(price);
        return (ethAmount.mul(price).div(ONE) == daiAmount) ? ethAmount : (ethAmount.add(1));
    }

    /**
     * @dev     Get current cdp main info: collateral amount, dai (debt) amount
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  ink     collateral tokens amount
     *          art     dai debt amount
     */
    function getCdpInfo(bytes32 ilk, uint cdpId) public view returns(uint ink, uint art) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (ink, art) = VatLike(mcdVatAddr).urns(ilk, urn);
    }

    /**
     * @dev     Get collateral token price to USD
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getPrice(bytes32 ilk) public view returns(uint) {
        return getSafePrice(ilk).mul(getLiquidationRatio(ilk)).div(ONE);
    }

    /**
     * @dev     Get collateral token safe price to USD. Equals current origin price devided by liquidation ratio
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getSafePrice(bytes32 ilk) public view returns(uint) {
        (,, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        return spot;
    }

    /**
     * @dev     Get collateral liquidation ratio. Percent of overcollateralization. If collateral / debt < liauidation ratio - cdp should be autoliquidated
     * @param   ilk     collateral type in bytes32 format
     * @return  liquidation ratio  150 * 10^25 - means 150%
     */
    function getLiquidationRatio(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @dev     Check is cdp is unsafe already
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  true if unsafe
     */
    function isCdpSafe(bytes32 ilk, uint cdpId) public view returns(bool) {
        return getDaiAvailable(ilk, cdpId) > 0;
    }

    /**
     * @dev     Calculate available dai to be drawn in Cdp
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  dai amount available to be drawn
     */
    function getDaiAvailable(bytes32 ilk, uint cdpId) public view returns(uint) {
        (, uint rate, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, ManagerLike(cdpManagerAddr).urns(cdpId));
        return (ink.mul(spot) > art.mul(rate)) ? fromRay(ink.mul(spot).sub(art.mul(rate))) : 0;
    }

    /**
     * @dev     Calculate current cdp collateralization ratio
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  collateralization ratio
     */
    function getCdpCR(bytes32 ilk, uint cdpId) public view returns(uint) {
        (, uint rate, uint spot,,) = VatLike(mcdVatAddr).ilks(ilk);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, ManagerLike(cdpManagerAddr).urns(cdpId));
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return ink.mul(spot).mul(mat).div(art.mul(rate));
    }

    /**
     * @dev     Get minimal collateralization ratio for collateral type
     * @param   ilk     collateral type in bytes32 format
     * @return  minimal collateralization ratio
     */
    function getMCR(bytes32 ilk) public view returns(uint) {
        (,uint mat) = SpotterLike(mcdSpotAddr).ilks(ilk);
        return mat;
    }

    /**
     * @dev    init mcd Wrapper, build proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   isEther  true if ether and false if erc-20 token
     */
    function _initMcdWrapper(bytes32 ilk, bool isEther) internal {
        _buildProxy();
        if (!isEther) {
            _approveERC20(ilk, proxyAddress, 2 ** 256 - 1);
        }
        _approveDai(proxyAddress, 2 ** 256 - 1);
    }

    /**
     * @dev    Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() internal {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev     Change proxy owner to a new one
     * @param   newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) internal {
        proxy().setOwner(newOwner);
    }

    /**
     * @dev     Lock additional ether as collateral
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     */
    function _lockETH(bytes32 ilk, uint cdp, uint wadC) internal {
        bytes memory data;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        data = abi.encodeWithSignature(
            "lockETH(address,address,uint256)",
            cdpManagerAddr, collateralJoinAddr, cdp);
        (bool success,) = proxyAddress.call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
        require(success, "failed to lock eth");
    }

    /**
     * @dev     Lock additional erc-20 tokens as collateral
     * @param   ilk     collateral type in bytes32 format
     * @param   cdp     cdp id
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _lockERC20(bytes32 ilk, uint cdp, uint wadC, bool transferFrom) internal {
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "lockGem(address,address,uint256,uint256,bool)",
                cdpManagerAddr, collateralJoinAddr, cdp, wadC, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @dev     build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     */
    function _openLockETHAndDraw(bytes32 ilk, uint wadC, uint wadD) internal returns (uint cdp) {
        address payable target = proxyAddress;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory data = abi.encodeWithSignature(
            "execute(address,bytes)",
            proxyLib,
            abi.encodeWithSignature(
                "openLockETHAndDraw(address,address,address,address,bytes32,uint256)",
                cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadD));
        assembly {
            let succeeded := call(sub(gas, 5000), target, wadC, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cdp := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @dev     build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadC    collateral amount to be locked in cdp contract
     * @param   wadD    dai amount to be drawn
     * @param   transferFrom   collateral tokens should be transfered from caller
     */
    function _openLockERC20AndDraw(bytes32 ilk, uint wadC, uint wadD, bool transferFrom) internal returns (uint cdp) {
        // _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory response = proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)",
                cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD, transferFrom));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev     inject(wipe) some amount of dai to cdp from agreement (pay off some amount of dai to cdp)
     * @param   cdp   cdp ID
     * @param   wad   amount of dai tokens
     */
    function _injectToCdpFromDsr(uint cdp, uint wad) internal returns(uint injectionWad) {
        injectionWad = _unlockDai(wad);
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "wipe(address,address,uint256,uint256)",
                cdpManagerAddr, mcdJoinDaiAddr, cdp, injectionWad));
    }

    /**
     * @dev     draw dai into cdp contract, if not enough - draw max available dai
     * @param   ilk   collateral type in bytes32 format
     * @param   cdp   cdp ID
     * @param   wad   amount of dai tokens
     * @return  drawn dai amount
     */
    function _drawDaiToCdp(bytes32 ilk, uint cdp, uint wad) internal returns (uint drawnDai) {
        JugLike(mcdJugAddr).drip(ilk);
        uint maxToDraw = getDaiAvailable(ilk, cdp);
        drawnDai = wad > maxToDraw ? maxToDraw : wad;
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "draw(address,address,address,uint256,uint256)",
                cdpManagerAddr, mcdJugAddr, mcdJoinDaiAddr, cdp, drawnDai));
    }
    /**
     * @dev     lock dai tokens to dsr(pot) contract.
     * @dev     approves this amount of dai tokens to proxy before locking
     * @param   wad amount of dai tokens
     */
    function _lockDai(uint wad) internal {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "join(address,address,uint256)",
                mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock dai tokens from dsr(pot) contract.
     * @param   wad amount of dai tokens
     * @return  actually unlocked amount of dai
     */
    function _unlockDai(uint wad) internal returns(uint unlockedWad) {
        uint _balanceBefore = _balanceDai(address(this));
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "exit(address,address,uint256)",
                mcdJoinDaiAddr, mcdPotAddr, wad));
        unlockedWad = _balanceDai(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function _unlockAllDai() internal returns(uint pie) {
        uint _balanceBefore = _balanceDai(address(this));
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature(
                "exitAll(address,address)",
                mcdJoinDaiAddr, mcdPotAddr));
        pie = _balanceDai(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev     Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     Approve exact amount of erc20 tokens for transferFrom
     * @param   ilk     collateral type
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).approve(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) internal returns(bool) {
        IERC20(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @dev     Transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
        return IERC20(mcdDaiAddr).transferFrom(from, to, amount);
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) internal returns(bool) {
        return erc20TokenContract(ilk).transferFrom(from, to, amount);
    }

    /**
     * @dev     Transfer Cdp ownership to guy's proxy
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function _transferCdpOwnershipToProxy(uint cdp, address guy) internal {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature(
                "giveToProxy(address,address,uint256,address)",
                proxyRegistryAddrMD, cdpManagerAddr, cdp, guy));
    }

    /**
     * @dev     Get balance of dai tokens
     * @param   addr      address
     */
    function _balanceDai(address addr) internal view returns(uint) {
        return IERC20(mcdDaiAddr).balanceOf(addr);
    }

    /**
     * @dev     Transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type 
     * @return  token adapter address
     * @return  token erc20 contract address
     */
    function _getCollateralAddreses(bytes32 ilk) internal view returns(address, address payable) {

        if (ilk == "ETH-A") {
            return (mcdJoinEthaAddr, wethAddr);
        }
        if (ilk == "BAT-A") {
            return (mcdJoinBataAddr, batAddr);
        }
        if (ilk == "WBTC-A") {
            return (mcdJoinWbtcaAddr, wbtcAddr);
        }
        if (ilk == "USDC-A") {
            return (mcdJoinUsdcaAddr, usdcAddr);
        }
        if (ilk == "USDC-B") {
            return (mcdJoinUsdcbAddr, usdcAddr);
        }

        // actual registry
        address _gem = IlkRegistryLike(mcdIlkRegAddr).gem(ilk);
        address payable _join = IlkRegistryLike(mcdIlkRegAddr).join(ilk);
        return (_gem, _join);        
    }
    
}
