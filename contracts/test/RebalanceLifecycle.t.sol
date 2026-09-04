// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MockERC20} from "../src/mocks/MockERC20.sol";
import {LpRewardVault} from "../src/core/LpRewardVault.sol";
import {RebalanceAuction} from "../src/core/RebalanceAuction.sol";
import {RebalanceController} from "../src/core/RebalanceController.sol";
import {RebalanceRightsHook} from "../src/hook/RebalanceRightsHook.sol";
import {RebalanceRouter, IProtectedHook} from "../src/core/RebalanceRouter.sol";
import {IERC20, ILpRewardVault, IRebalanceAuction, IRebalanceController} from "../src/interfaces/IRR.sol";

interface Vm {
    function prank(address caller) external;
    function warp(uint256 timestamp) external;
    function roll(uint256 height) external;
}

/// @notice Canonical local simulation: 60/40 LPs, price shock, auction, correction, and reward claims.
contract RebalanceLifecycleTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant ALICE = address(0xA11CE);
    address private constant BAO = address(0xBA0);
    address private constant LATE = address(0x1A7E);
    address private constant SEARCHER_A = address(0x51);
    address private constant SEARCHER_B = address(0x52);
    address private constant CALLBACK_PROXY = address(0xCA11BAC);
    address private constant RVM_ID = address(0xA11CE123);
    bytes32 private constant POOL = keccak256("ETH-USDC-DEMO");
    uint160 private constant INITIAL_PRICE = 2_000e18;
    uint160 private constant SHOCK_PRICE = 2_120e18;

    MockERC20 private liquidity;
    MockERC20 private bidToken;
    LpRewardVault private vault;
    RebalanceController private controller;
    RebalanceAuction private auction;
    RebalanceRightsHook private hook;
    RebalanceRouter private router;

    function setUp() public {
        liquidity = new MockERC20("Demo LP asset", "DLP");
        bidToken = new MockERC20("Demo WETH", "dWETH");
        vault = new LpRewardVault(IERC20(address(liquidity)), IERC20(address(bidToken)));
        controller = new RebalanceController(ILpRewardVault(address(vault)), CALLBACK_PROXY, RVM_ID, 100, 60, 120, 10 ether);
        auction = new RebalanceAuction(IERC20(address(bidToken)), address(controller), address(vault));
        hook = new RebalanceRightsHook(IRebalanceController(address(controller)));
        router = new RebalanceRouter(IProtectedHook(address(hook)));
        vault.setController(address(controller));
        controller.setAuction(IRebalanceAuction(address(auction)));
        controller.setHook(address(hook));
        hook.setRouter(address(router));

        liquidity.mint(ALICE, 60 ether);
        liquidity.mint(BAO, 40 ether);
        liquidity.mint(LATE, 25 ether);
        bidToken.mint(SEARCHER_A, 10 ether);
        bidToken.mint(SEARCHER_B, 10 ether);
        _deposit(ALICE, 60 ether);
        _deposit(BAO, 40 ether);
        hook.observePool(POOL, INITIAL_PRICE, 0);
        vm.roll(block.number + 1);
    }

    function test_CompleteLifecycleAllocatesWinningBidToPreShockLps() public {
        uint256 windowId = _openShock();
        _bid(SEARCHER_A, windowId, 1 ether);
        _bid(SEARCHER_B, windowId, 1.5 ether);
        vm.warp(block.timestamp + 61);
        controller.finalizeWindow(windowId);
        RebalanceController.Window memory window = controller.getWindow(windowId);
        _assertEq(uint256(uint160(window.winner)), uint256(uint160(SEARCHER_B)), "highest bidder did not win");

        vm.roll(block.number + 1);
        _deposit(LATE, 25 ether);
        vm.prank(SEARCHER_B);
        router.swapWithPermit(POOL, windowId, window.permitNonce, true, 5 ether, SHOCK_PRICE);
        vm.prank(SEARCHER_B);
        (bool repeatUse,) = address(router).call(
            abi.encodeCall(router.swapWithPermit, (POOL, windowId, window.permitNonce, true, 1 ether, SHOCK_PRICE))
        );
        _assertFalse(repeatUse, "consumed permit executed twice");
        vm.prank(CALLBACK_PROXY);
        controller.markCorrected(RVM_ID, windowId, 2);

        vm.prank(ALICE);
        _assertEq(vault.claim(windowId), 0.9 ether, "Alice reward is wrong");
        vm.prank(BAO);
        _assertEq(vault.claim(windowId), 0.6 ether, "Bao reward is wrong");
        vm.prank(LATE);
        _assertEq(vault.claim(windowId), 0, "late LP received reward");
        _assertEq(bidToken.balanceOf(address(vault)), 0, "reward vault retained distributable funds");
    }

    function test_BelowThresholdAndDuplicateCallbackDoNotOpenWindows() public {
        vm.prank(CALLBACK_PROXY);
        (bool smallShock,) = address(controller).call(
            abi.encodeCall(controller.openWindow, (RVM_ID, POOL, uint160(2_010e18), 1, 1))
        );
        _assertFalse(smallShock, "below threshold shock opened a window");

        uint256 windowId = _openShock();
        vm.prank(CALLBACK_PROXY);
        (bool replay,) = address(controller).call(
            abi.encodeCall(controller.openWindow, (RVM_ID, POOL, SHOCK_PRICE, 2, 1))
        );
        _assertFalse(replay, "callback nonce replay opened a window");
        _assertEq(controller.activeWindowForPool(POOL), windowId, "wrong active window");
    }

    function test_RejectsUnauthorizedCallbacksAndInvalidPermits() public {
        (bool directOpen,) = address(controller).call(
            abi.encodeCall(controller.openWindow, (RVM_ID, POOL, SHOCK_PRICE, 1, 1))
        );
        _assertFalse(directOpen, "untrusted callback opened a window");
        vm.prank(CALLBACK_PROXY);
        (bool wrongRvm,) = address(controller).call(
            abi.encodeCall(controller.openWindow, (address(0xBEEF), POOL, SHOCK_PRICE, 1, 1))
        );
        _assertFalse(wrongRvm, "unexpected RVM opened a window");

        uint256 windowId = _openShock();
        _bid(SEARCHER_B, windowId, 2 ether);
        vm.warp(block.timestamp + 61);
        controller.finalizeWindow(windowId);
        RebalanceController.Window memory window = controller.getWindow(windowId);
        vm.prank(SEARCHER_A);
        (bool loserUsed,) = address(router).call(
            abi.encodeCall(router.swapWithPermit, (POOL, windowId, window.permitNonce, true, 1 ether, SHOCK_PRICE))
        );
        _assertFalse(loserUsed, "losing searcher used permit");
        vm.prank(SEARCHER_B);
        (bool oversized,) = address(router).call(
            abi.encodeCall(router.swapWithPermit, (POOL, windowId, window.permitNonce, true, 11 ether, SHOCK_PRICE))
        );
        _assertFalse(oversized, "oversized correction succeeded");
        vm.prank(SEARCHER_B);
        (bool wrongDirection,) = address(router).call(
            abi.encodeCall(router.swapWithPermit, (POOL, windowId, window.permitNonce, false, 1 ether, SHOCK_PRICE))
        );
        _assertFalse(wrongDirection, "wrong direction succeeded");
    }

    function test_ExpiredPermitRefundsWinnerAndCannotExecute() public {
        uint256 windowId = _openShock();
        _bid(SEARCHER_B, windowId, 2 ether);
        vm.warp(block.timestamp + 61);
        controller.finalizeWindow(windowId);
        RebalanceController.Window memory window = controller.getWindow(windowId);
        vm.warp(block.timestamp + 121);
        controller.expireWindow(windowId);
        vm.prank(SEARCHER_B);
        auction.withdrawRefund();
        _assertEq(bidToken.balanceOf(SEARCHER_B), 10 ether, "winner was not fully refunded");
        vm.prank(SEARCHER_B);
        (bool expiredUsed,) = address(router).call(
            abi.encodeCall(router.swapWithPermit, (POOL, windowId, window.permitNonce, true, 1 ether, SHOCK_PRICE))
        );
        _assertFalse(expiredUsed, "expired permit executed");
    }

    function testFuzz_ClaimsNeverExceedWinningBid(uint96 rawBid) public {
        uint256 winningBid = uint256(rawBid % 1_000_000_000_000_000_000) + 2 ether;
        bidToken.mint(SEARCHER_B, winningBid);
        uint256 windowId = _openShock();
        _bid(SEARCHER_A, windowId, 1 ether);
        _bid(SEARCHER_B, windowId, winningBid);
        vm.warp(block.timestamp + 61);
        controller.finalizeWindow(windowId);
        RebalanceController.Window memory window = controller.getWindow(windowId);
        vm.prank(SEARCHER_B);
        router.swapWithPermit(POOL, windowId, window.permitNonce, true, 1 ether, SHOCK_PRICE);
        vm.prank(ALICE);
        uint256 aliceReward = vault.claim(windowId);
        vm.prank(BAO);
        uint256 baoReward = vault.claim(windowId);
        _assertTrue(aliceReward + baoReward <= winningBid, "claims exceed collateral");
    }

    function _openShock() private returns (uint256 windowId) {
        vm.prank(CALLBACK_PROXY);
        windowId = controller.openWindow(RVM_ID, POOL, SHOCK_PRICE, 1, 1);
    }

    function _bid(address bidder, uint256 windowId, uint256 amount) private {
        vm.prank(bidder);
        bidToken.approve(address(auction), amount);
        vm.prank(bidder);
        auction.bid(windowId, amount);
    }

    function _deposit(address lp, uint256 amount) private {
        vm.prank(lp);
        liquidity.approve(address(vault), amount);
        vm.prank(lp);
        vault.deposit(amount);
    }

    function _assertEq(uint256 actual, uint256 expected, string memory reason) private pure { require(actual == expected, reason); }
    function _assertFalse(bool value, string memory reason) private pure { require(!value, reason); }
    function _assertTrue(bool value, string memory reason) private pure { require(value, reason); }
}
