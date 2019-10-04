pragma solidity >=0.5.0;

import './config/McdConfig.sol';
import './interfaces/McdInterfaces.sol';
import './interfaces/ERC20Interface.sol';

/**
 * @title Agreement multicollateral dai wrapper for maker dao system interaction.
 * @dev delegates calls to proxy. Oriented to exact MCD release. Current version oriented to 6th release mcd cdp.
 */
contract McdWrapper is McdConfig {
    address public proxyAddr;
    mapping(bytes32 => bool) collateralTypesAvailable;
    /**
     * @dev Build proxy for current caller (msg.sender address)
     */
    function buildProxy() public returns (address payable) {
        return ProxyRegistryLike(proxyRegistryAddr).build();
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxy() public view returns (DSProxyLike) {
        if (proxyAddr == address(0)) {
            return DSProxyLike(buildProxy());
        } else {
            return DSProxyLike(proxyAddr);
        }
    }

    /**
     * @dev Get registered proxy for current caller (msg.sender address)
     */
    function proxyAddress() public view returns (address) {
        if (proxyAddr == address(0)) {
            return buildProxy();
        } else {
            return proxyAddr;
        }
    }

    /**
     * @dev Change proxy owner to a new one
     * @param newOwner new owner address
     */
    function setOwnerProxy(address newOwner) public {
        proxy().setOwner(newOwner);
    }

    function openCdp(bytes32 ilk) public returns (uint cdp) {
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'open(address,bytes32,uint256,uint256)',
            cdpManagerAddr, ilk));
        assembly {
            cdp := mload(add(response, 0x20))
        }
    }

    function lockETHAndDraw(bytes32 ilk, uint cdp, uint wadC, uint wadD) public {
        bytes memory data;
        data = abi.encodeWithSignature(
            'lockETHAndDraw(address,address,address,address,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes(ilk).mcdJoinAddr, mcdJoinDaiAddr, cdp, wadD);
        proxyAddress().call.value(wadC)(abi.encodeWithSignature("execute(address,bytes)", proxyLib, data));
    }

    /**
     * @dev     Create new cdp with ERC-20 tokens as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation and approve transferFrom collateral token from Agrrement by Proxy
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function lockERC20AndDraw(bytes32 ilk, uint cdp, uint wadD, uint wadC, bool transferFrom) public {
        approveERC20(ilk, proxy(), wadC);
        proxy().execute(proxyLib, abi.encodeWithSignature(
            'lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)',
            cdpManagerAddr, mcdJugAddr, collateralTypes(ilk).mcdJoinAddr, mcdJoinDaiAddr, cdp, wadC, wadD, transferFrom));
    }

    /**
     * @dev     Create new cdp with Ether as collateral, lock collateral and draw dai
     * @notice  build new Proxy for a caller before cdp creation
     * @param   ilk     collateral type in bytes32 format
     * @param   wadD    dai amount to be drawn
     * @param   wadC    collateral amount to be locked in cdp contract
     * @return  cdp     cdp ID
     */
    function openLockETHAndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        bytes memory data = abi.encodeWithSignature(
            'execute(address,bytes)',
            proxyLib,
            abi.encodeWithSignature('openLockETHAndDraw(address,address,address,address,bytes32,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes(ilk).mcdJoinAddr, mcdJoinDaiAddr, ilk, wadD));
        assembly {
            let succeeded := call(sub(gas, 5000), proxyAddress(), wadC, add(data, 0x20), mload(data), 0, 0)
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
    function openLockERC20AndDraw(bytes32 ilk, uint wadD, uint wadC) public returns (uint cdp) {
        approveERC20(ilk, proxy(), wadC);
        bytes memory response = proxy().execute(proxyLib, abi.encodeWithSignature(
            'openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256)',
            cdpManagerAddr, mcdJugAddr, collateralTypes(ilk).mcdJoinAddr, mcdJoinDaiAddr, ilk, wadC, wadD));
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
    function injectToCdp(uint cdp, uint wad) public {
        approveDai(address(proxy()), wad);
        wipe(cdp, wad);
    }

    /**
     * @dev pay off some amount of dai to cdp
     * @param cdp cdp ID
     * @param wad amount of dai tokens
     */
    function wipe(uint cdp, uint wad) public {
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
    function lockDai(uint wad) public {
        // transfer dai from borrower to agreement
        transferFromDai(msg.sender, address(this), wad);
        approveDai(address(proxy()), wad);
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('join(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev unlock dai tokens from dsr(pot) contract.
     * @param wad amount of dai tokens
     */
    function unlockDai(uint wad) public {
        proxy().execute(
            proxyLibDsr,
            abi.encodeWithSignature('exit(address,address,uint256)',
            mcdJoinDaiAddr, mcdPotAddr, wad));
    }

    /**
     * @dev     unlock all dai tokens from dsr(pot) contract.
     * @return  pie amount of all dai tokens was unlocked in fact
     */
    function unlockAllDai() public returns(uint pie) {
        pie = getLockedDai();
        unlockDai(pie);
        // function will be available in further releases (11)
        //proxy().execute(proxyLib, abi.encodeWithSignature("exitAll(address,address)", mcdJoinDaiAddr, mcdPotAddr));
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
    function forceLiquidate(bytes32 ilk, uint cdpId) public view returns(uint) {
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
    function approveDai(address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     Approve exact amount of erc20 tokens for transferFrom
     * @param   to      address allowed to call transferFrom
     * @param   amount  tokens amount for approval
     */
    function approveERC20(bytes32 ilk, address to, uint amount) public returns(bool) {
        ERC20Interface(collateralTypes(ilk).mcdJoinAddr).approve(to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of dai tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function transferFromDai(address from, address to, uint amount) public returns(bool) {
        ERC20Interface(mcdDaiAddr).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev     transfer exact amount of erc20 tokens, approved beforehand
     * @param   from    address of spender
     * @param   to      address of recepient
     * @param   amount  tokens amount
     */
    function transferFromERC20(bytes32 ilk, address from, address to, uint amount) public returns(bool) {
        ERC20Interface(collateralTypes(ilk).baseAddr).transferFrom(from, to, amount);
        return true;
    }
    
    /**
     * @dev     Transfer Cdp ownership
     * @param   cdp     cdp ID
     * @param   guy     address, ownership should be transfered to
     */
    function transferCdpOwnership(uint cdp, address guy) public {
        proxy().execute(
            proxyLib,
            abi.encodeWithSignature('give(address,uint256,address)',
            cdpManagerAddr, cdp, guy));
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
}
