// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {DemoLiquidityManager} from "../src/mocks/DemoLiquidityManager.sol";
import {LpRewardVault} from "../src/core/LpRewardVault.sol";
import {RebalanceController} from "../src/core/RebalanceController.sol";
import {RebalanceAuction} from "../src/core/RebalanceAuction.sol";
import {UniswapV4RebalanceRouter} from "../src/v4/UniswapV4RebalanceRouter.sol";
import {UniswapV4RebalanceRightsHook} from "../src/hook/UniswapV4RebalanceRightsHook.sol";
import {UniswapV4RebalanceHookFactory} from "../src/deploy/UniswapV4RebalanceHookFactory.sol";
import {IERC20, ILpRewardVault, IRebalanceAuction, IRebalanceController} from "../src/interfaces/IRR.sol";

contract RebalanceV4IntegrationTest is Test {
    using PoolIdLibrary for PoolKey;

    uint160 private constant SQRT_PRICE_1_1 = 79_228_162_514_264_337_593_543_950_336;
    address private constant ALICE = address(0xA11CE);
    address private constant BAO = address(0xBA0);
    address private constant SEARCHER_A = address(0x51);
    address private constant SEARCHER_B = address(0x52);
    address private constant CALLBACK_PROXY = address(0xCA11BAC);
    address private constant RVM_ID = address(0xA11CE123);

    MockERC20 private token0;
    MockERC20 private token1;
    MockERC20 private lpToken;
    MockERC20 private bidToken;
    PoolManager private manager;
    LpRewardVault private vault;
    RebalanceController private controller;
    RebalanceAuction private auction;
    UniswapV4RebalanceRouter private router;
    UniswapV4RebalanceRightsHook private hook;
    PoolKey private key;

    function setUp() public {
        manager = new PoolManager(address(this));
        (token0, token1) = _deploySortedTokens();
        lpToken = new MockERC20("Demo LP share", "DLP");
        bidToken = new MockERC20("Demo WETH", "dWETH");
        vault = new LpRewardVault(IERC20(address(lpToken)), IERC20(address(bidToken)));
        controller = new RebalanceController(
            ILpRewardVault(address(vault)), CALLBACK_PROXY, RVM_ID, 100, 20, 120, 10 ether
        );
        auction = new RebalanceAuction(IERC20(address(bidToken)), address(controller), address(vault));
        router = new UniswapV4RebalanceRouter(manager);

        UniswapV4RebalanceHookFactory factory = new UniswapV4RebalanceHookFactory();
        (address predictedHook, bytes32 salt) =
            factory.findSalt(manager, IRebalanceController(address(controller)), address(router));
        hook = factory.deployHook(salt, manager, IRebalanceController(address(controller)), address(router));
        assertEq(address(hook), predictedHook);

        vault.setController(address(controller));
        controller.setAuction(IRebalanceAuction(address(auction)));
        controller.setHook(address(hook));
        router.setHook(address(hook));

        key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3_000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
        manager.initialize(key, SQRT_PRICE_1_1);
        _seedPoolLiquidity();
        _seedLpSnapshot();
        _fundSearchers();
    }

    function test_RealV4SwapConsumesWinnerPermitAndPaysSnapshotLps() public {
        vm.startPrank(SEARCHER_A);
        token0.approve(address(router), type(uint256).max);
        router.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -int256(0.001 ether),
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            })
        );
        vm.stopPrank();

        bytes32 poolId = PoolId.unwrap(key.toId());
        uint160 observedPrice = controller.latestPoolPriceE18(poolId);
        assertGt(observedPrice, 0.99 ether);
        assertLt(observedPrice, 1 ether);
        uint160 referencePrice = uint160(uint256(observedPrice) * 106 / 100);

        vm.prank(CALLBACK_PROXY);
        uint256 windowId = controller.openWindow(RVM_ID, poolId, referencePrice, 1, 1);
        _bid(SEARCHER_A, windowId, 1 ether);
        _bid(SEARCHER_B, windowId, 1.5 ether);
        vm.warp(block.timestamp + 21);
        controller.finalizeWindow(windowId);
        RebalanceController.Window memory window = controller.getWindow(windowId);
        assertEq(window.winner, SEARCHER_B);

        vm.startPrank(SEARCHER_B);
        token1.approve(address(router), type(uint256).max);
        router.swapWithPermit(
            key,
            SwapParams({
                zeroForOne: false,
                amountSpecified: -int256(5 ether),
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
            }),
            windowId,
            window.permitNonce
        );
        vm.expectRevert();
        router.swapWithPermit(
            key,
            SwapParams({
                zeroForOne: false,
                amountSpecified: -int256(1 ether),
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
            }),
            windowId,
            window.permitNonce
        );
        vm.stopPrank();

        assertEq(uint8(controller.getWindow(windowId).state), uint8(RebalanceController.WindowState.Consumed));
        vm.prank(ALICE);
        assertEq(vault.claim(windowId), 0.9 ether);
        vm.prank(BAO);
        assertEq(vault.claim(windowId), 0.6 ether);
    }

    function _seedPoolLiquidity() private {
        DemoLiquidityManager liquidityManager = new DemoLiquidityManager(manager);
        token0.mint(address(this), 1e30);
        token1.mint(address(this), 1e30);
        token0.approve(address(liquidityManager), type(uint256).max);
        token1.approve(address(liquidityManager), type(uint256).max);
        liquidityManager.addLiquidity(key, -60_000, 60_000, 1e21, keccak256("demo-liquidity"));
    }

    function _seedLpSnapshot() private {
        lpToken.mint(ALICE, 60 ether);
        lpToken.mint(BAO, 40 ether);
        vm.startPrank(ALICE);
        lpToken.approve(address(vault), type(uint256).max);
        vault.deposit(60 ether);
        vm.stopPrank();
        vm.startPrank(BAO);
        lpToken.approve(address(vault), type(uint256).max);
        vault.deposit(40 ether);
        vm.stopPrank();
        vm.roll(block.number + 1);
    }

    function _fundSearchers() private {
        token0.mint(SEARCHER_A, 10 ether);
        token1.mint(SEARCHER_B, 10 ether);
        bidToken.mint(SEARCHER_A, 10 ether);
        bidToken.mint(SEARCHER_B, 10 ether);
    }

    function _bid(address bidder, uint256 windowId, uint256 amount) private {
        vm.startPrank(bidder);
        bidToken.approve(address(auction), amount);
        auction.bid(windowId, amount);
        vm.stopPrank();
    }

    function _deploySortedTokens() private returns (MockERC20 first, MockERC20 second) {
        MockERC20 a = new MockERC20("Token A", "TKA");
        MockERC20 b = new MockERC20("Token B", "TKB");
        return address(a) < address(b) ? (a, b) : (b, a);
    }
}
