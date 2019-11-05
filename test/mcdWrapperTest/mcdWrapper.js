// This test suite will be working if being run all together by using script from package.json.
// Any uncareful changes or running some separated test can easily fail.

const McdWrapper = artifacts.require('McdWrapperMock');
const ERC20Token = artifacts.require('SimpleErc20Token');

const daiTokenAddress = '0xc7cC3413f169a027dccfeffe5208Ca4f38eF0c40';
const repTokenAddress = '0xc7aa227823789e363f29679f23f7e8f6d9904a9b';

const SOME_ADDRESS = '0x0000000000000000000000000000000000000001';
// const REP_A = '0x5245502d41000000000000000000000000000000000000000000000000000000';
const ETH_A = '0x4554482d41000000000000000000000000000000000000000000000000000000';
const wethAddr = '0xd0A1E359811322d97991E03f863a0C30C2cF029C';
const mcdJoinEthaAddr = '0xc3AbbA566bb62c09b7f94704d8dFd9800935D3F9';

contract('McdWrapper', async (accounts) => {
  let mcdWrapper;
  let cdpId;
  let daiToken;
  // let repToken;

  before('setup', async () => {
    mcdWrapper = await McdWrapper.new();
    daiToken = await ERC20Token.at(daiTokenAddress);
    repToken = await ERC20Token.at(repTokenAddress);
  });

  describe('mcdWrapper functions validation', async () => {
    it('initMcdWrapper() should not fail', async () => {
      await mcdWrapper.initMcdWrapper();
    });

    it('setOwnerProxy() should not fail', async () => {
      await mcdWrapper.setOwnerProxy.call(SOME_ADDRESS);
    });

    it('openCdp() should not fail', async () => {
      await mcdWrapper.openCdp(ETH_A);
      cdpId = (await mcdWrapper.cdpId()).toNumber();
      assert.isTrue(cdpId > 0);
    });

    it('lockETHAndDraw() should not fail', async () => {
      await mcdWrapper.send(100);
      await mcdWrapper.lockETHAndDraw(ETH_A, cdpId, 100, 16000);
    });

    // it.only('lockERC20AndDraw() should not fail', async () => {
    //   await repToken.transfer(mcdWrapper.address, 100);
    //   await mcdWrapper.lockERC20AndDraw(REP_A, cdpId, 100, 10, true);
    // });

    it('injectToCdp() should not fail', async () => {
      await daiToken.transfer(mcdWrapper.address, 100);
      await mcdWrapper.injectToCdp(cdpId, 100);
    });

    it('lockDai() should not fail', async () => {
      await daiToken.transfer(mcdWrapper.address, 100);
      await mcdWrapper.lockDai(100);
    });

    it('unlockDai() should not fail', async () => {
      await mcdWrapper.unlockDai(50);
    });

    it('unlockAllDai() should not fail', async () => {
      await mcdWrapper.unlockAllDai();
    });

    it('transferCdpOwnership() should not fail', async () => {
      await mcdWrapper.transferCdpOwnership(cdpId, SOME_ADDRESS);
    });

    it('proxy() should not fail', async () => {
      assert.equal(await mcdWrapper.proxy(), await mcdWrapper.proxyAddress());
    });

    it('erc20TokenContract() should not fail', async () => {
      assert.equal(await mcdWrapper.erc20TokenContract(ETH_A), wethAddr);
    });

    it('getLockedDai() should not fail', async () => {
      await daiToken.transfer(mcdWrapper.address, 205);
      await mcdWrapper.lockDai(205);

      assert.equal((await mcdWrapper.getLockedDai()).pie.toString(), '204');
    });

    it('getDsr() should not fail', async () => {
      assert.isTrue(await mcdWrapper.getDsr() > 0);
    });

    it('getCollateralEquivalent() should not fail', async () => {
      assert.isTrue(await mcdWrapper.getCollateralEquivalent(ETH_A, 25) > 0);
    });

    it('getCdpInfo() should not fail', async () => {
      const result = await mcdWrapper.getCdpInfo(ETH_A, cdpId);

      assert.isTrue(result.ink > 0);
      assert.isTrue(result.art > 0);
    });

    it('getPrice() should not fail', async () => {
      assert.isTrue(await mcdWrapper.getPrice(ETH_A) > 0);
    });

    it('getLiquidationRatio() should not fail', async () => {
      assert.isTrue(await mcdWrapper.getLiquidationRatio(ETH_A) > 0);
    });

    it('getLiquidationRatio() should not fail', async () => {
      assert.isTrue(await mcdWrapper.getLiquidationRatio(ETH_A) > 0);
    });

    it('isCDPLiquidated() should not fail', async () => {
      assert.isFalse(await mcdWrapper.isCDPLiquidated(ETH_A, cdpId));
    });

    it('getCollateralDetails() should not fail', async () => {
      const result = await mcdWrapper.getCollateralDetails(ETH_A);

      assert.isTrue(result._price > 0);
      assert.isTrue(result._duty > 0);
      assert.isTrue(result._mats > 0);
      assert.isTrue(result._chop > 0);
    });

    it('getCollateralAddreses() should not fail', async () => {
      const result = await mcdWrapper.getCollateralAddreses(ETH_A);

      assert.equal(result.wethAddr, wethAddr);
      assert.equal(result.mcdJoinEthaAddr, mcdJoinEthaAddr);
    });
  });
});
