pragma solidity >=0.5.0;

import '../config/McdAddresses.sol';
import '../interfaces/McdInterfaces.sol';
import '../interfaces/ERC20Interface.sol';
import './RaySupport.sol';

/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdAddressesR14, RaySupport {
    address payable public proxyAddress;

    function _initMcdWrapper() internal {
        _buildProxy();
    }

    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function _buildProxy() internal {
        proxyAddress = ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function _setOwnerProxy(address newOwner) internal {
        proxy().setOwner(newOwner);
    }

    function _openCdp(bytes32 ilk) internal returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'open(address,bytes32)',
            cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function _lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) internal {
        bytes memory data;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        data = abi.encodeWithSignature(
            'lockETHAndDraw(address,address,address,address,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, cdp, wadD);
        proxyAddress.call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) internal {
        _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(proxyLib, abi.encodeWithSignature(
            'lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, cdp, wadC, wadD, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) internal returns (uint cdp) {
        address payable target = proxyAddress;
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory data = abi.encodeWithSignature(
            'execute(address,bytes)',
            proxyLib,
            abi.encodeWithSignature('openLockETHAndDraw(address,address,address,address,bytes32,uint256)',
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
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function _openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC, bool transferFrom) internal returns (uint cdp) {
        _approveERC20(ilk, proxyAddress, wadC);
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD, transferFrom));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    /**
     * @dev inject(wipe) some amount of dai to cdp from agreement
     * @notice approves this amount of dai tokens to proxy before injection
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function _injectToCdp(uint cdp, uint wad) internal {
        _approveDai(address(proxy()), wad);
        _wipe(cdp, wad);
    }

    /**
     * @dev pay off some amount of dai to cdp
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function _wipe(uint cdp, uint wad) internal {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('wipe(address,address,uint256,uint256)',
            cdpManagerAddr, mcdJoinDaiAddr, cdp, wad));
    }

    /**
     * @dev lock dai tokens to dsr(pot) contract.
     * @notice approves this amount of dai tokens to proxy before locking
     * @param wad amount of dai tokens
     */
    function _lockDai(uint wad) internal {
        // transfer dai from borrower to agreement
        _transferFromDai(msg.sender, address(this), wad);
        _approveDai(address(proxy()), wad);
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('join(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev unlock dai tokens from dsr(pot) contract.
     * @param wad amount of dai tokens
     */
    function _unlockDai(uint wad) internal {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('exit(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function _unlockAllDai() internal returns(uint pie) {
        pie = getLockedDai();
        _unlockDai(pie);
        // function will be available in further releases (11)
        //proxy().execute(proxyLib, abi.encodeWithSignature("exitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
    }

    function _cashETH(bytes32 ilk, uint wad) internal {
        (address collateralJoinAddr,) = _getCollateralAddreses(ilk);
        proxy().execute(
            proxyLibEnd,
            abi.encodeWithSignature('cashETH(address,address,bytes32,uint)',
            collateralJoinAddr, mcdEndAddr, ilk, wad));
    }

    /**
     * @dev     should invoke liquidation process on cdp contract to return back (collateral - equivalent debt)
     *          To determine how much collateral you would possess after a Liquidation you can use the following simplified formula:
     *          (Collateral * Oracle Price * PETH/ETH Ratio) - (Liquidation Penalty * Stability Debt) - Stability Debt = (Remaining Collateral * Oracle Price) DAI
     * @notice  !!! SHOULD BE REWRITTEN AFTER MCD CDP FINAL RELEASE !!!
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  amount of collateral tokens returned after liquidation
     */
    function _forceLiquidateCdp(bytes32 ilk, uint cdpId) internal view returns(uint) {
        address urn = ManagerLike(cdpManagerAddr).urns(cdpId);
        (uint ink, uint art) = VatLike(mcdVatAddr).urns(ilk, urn);

        // need to be clarified what it is in mcd.
        // In single collateral it is: The ratio of PETH/ETH is 1.012
        // solium-disable-next-line no-unused-vars
        (,uint rate,,,) = VatLike(mcdVatAddr).ilks(ilk);

        (,uint chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        uint price = getPrice(ilk);
        return (ink * price - (chop - ONE) * art) / price;
    }

    /**
     * @dev     Approve exact amount of dai tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function _approveDai(address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).approve(to, amount);
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
     * @dev     transfer exact amount of dai tokens
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferDai(address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens
     * @param   ilk     collateral type
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferERC20(bytes32 ilk, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transfer(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromDai(address from, address to, uint amount) internal returns(bool) {
        ERC20Interface(mcdDaiAddr).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     call transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _callTransferFromDai(address from, address to, uint amount) internal returns(bool) {
        (bool TransferSuccessful,) = mcdDaiAddr.call(abi.encodeWithSignature(
                'transferFrom(address,address,uint256)', from, to, amount));
        return TransferSuccessful;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function _transferFromERC20(bytes32 ilk, address from, address to, uint amount) internal returns(bool) {
        erc20TokenContract(ilk).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function _transferCdpOwnership(uint cdp, address guy) internal {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('give(address,uint256,address)',
            cdpManagerAddr, cdp, guy));
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        return DSProxyLike(proxyAddress);
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   ilk     collateral type
     * @return          ERC20Interface instance
     */
    function erc20TokenContract(bytes32 ilk) public view returns(ERC20Interface) {
        return ERC20Interface(collateralBaseAddress);
    }

    /**
     * @dev     get amount of dai tokens currently locked in dsr(pot) contract.
     * @return  pie amount of all dai tokens locked in dsr
     */
    function getLockedDai() public view returns(uint256) {
        return PotLike(mcdPotAddr).pie(address(proxy()));
    }

    /**
     * @dev     get dai savings rate
     * @return  dsr value in multiplier format defined by maker dao system. 100 * 10^25 - means 0% dsr. 103 * 10^25 means 3% dsr.
     */
    function getDsr() public view returns(uint) {
        return PotLike(mcdPotAddr).dsr();
    }

    /**
     * @dev     Get the equivalent of exact dai amount in terms of collateral type.
     * @notice  Add one more collateral token unit in case if calculated value doesn't cover dai amount
     * @param   ilk         collateral type in bytes32 format
     * @param   daiAmount   dai tokens amount
     * @return  collateral tokens amount worth dai amount
     */
    function getCollateralEquivalent(bytes32 ilk, uint daiAmount) public view returns(uint) {
        uint price = getPrice(ilk);
        uint ethAmount = daiAmount * ONE / price;
        if (ethAmount * price / ONE == daiAmount) {
            return ethAmount;
        } else {
            return ethAmount + 1;
        }
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
     * @notice  !!! SHOULD BE REWRITTEN AFTER MCD CDP FINAL RELEASE !!! Now is calculated as safe price multiplied with liquidation ratio
     * @param   ilk     collateral type in bytes32 format
     * @return  collateral to USD price
     */
    function getPrice(bytes32 ilk) public view returns(uint) {
        // should be rewritten after release, price is stored in pip contract. now returns empty
        //return _mcdPip().read();
        //(pip,) = SpotterLike(mcdCatAddr).ilks(ilk);
        return getSafePrice(ilk) * getLiquidationRatio(ilk) / ONE;
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
     * @dev     Check is cdp is liquidated already
     * @param   ilk     collateral type in bytes32 format
     * @param   cdpId   cdp ID
     * @return  liquidation ratio. For example 150 * 10^25 - means 150%
     */
    function isCDPLiquidated(bytes32 ilk, uint cdpId) public view returns(bool) {
        return false;
    }

    /**
     * @dev     Get collateral datailes
     * @param   ilk     collateral type in bytes32 format
     * @return  _price  collateral price to USD
     * @return  _duty   collateral stability fee
     * @return  _mat    collateral minimum liquidation ratio
     * @return  _chop   collateral liquidation penalty
     */
    function getCollateralDetails(bytes32 ilk) public view returns(uint _price, uint _duty, uint _mats, uint _chop) {
        PipLike pip;
        (pip, _mats) = SpotterLike(mcdSpotAddr).ilks(ilk); // mat - minimum col.ratio
        (_duty,) = JugLike(mcdJugAddr).ilks(ilk); // stability fee
        (, _chop,) = CatLike(mcdCatAddr).ilks(ilk); // penalty
        //_price = uint(pip.read());
        _price = getPrice(ilk);
    }

    function _getCollateralAddreses(bytes32 ilk) internal returns(address, address payable)  {
        if (ilk == "ETH-A") {
            return (mcdJoinEthaAddr, wethAddr);
        }
        if (ilk == "ETH-B") {
            return (mcdJoinEthbAddr, wethAddr);
        }
        // return (address(0), address(0));
    }
}
