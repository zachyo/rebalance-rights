# Rebalance Rights: Five-Minute Video Runbook

## Recording Format

- `0:00-2:00`: Six-slide pitch.
- `2:00-5:00`: Live testnet walkthrough.
- Record the walkthrough in clips. Remove chain-confirmation and Reactive-indexing waits in the edit.
- Start the walkthrough from the current state immediately after `ObservePool`.
- Do not trigger the `1.06` reference-price shock before recording its clip.

## Two-Minute Slide Script

### Slide 1: Correction Is an Asset (`0:00-0:15`)

**On screen:** Title slide.

**Say:**

> Rebalance Rights turns one stale-pool correction into an auctioned asset. Searchers compete for the right to correct the pool, and the winning bid goes back to the LPs who made that opportunity possible.

### Slide 2: The Problem (`0:15-0:37`)

**On screen:** External market, stale pool, and correction-value cards.

**Say:**

> When an external market moves before an AMM, the stale pool creates a valuable correction opportunity. Arbitrage keeps the market efficient, but that value comes from LP inventory. Our question is: what if LPs could sell access to the correction before it happens?

### Slide 3: The Primitive (`0:37-0:57`)

**On screen:** Detect, auction, enforce, return.

**Say:**

> Rebalance Rights creates a small market around one state transition. Reactive detects the event, searchers auction for the route, the hook enforces a winner-bound permit, and the payment is allocated to the historical LP snapshot.

### Slide 4: Cross-Chain Execution (`0:57-1:19`)

**On screen:** Base Sepolia, Reactive Lasna, and Unichain architecture.

**Say:**

> The reference event starts on Base Sepolia. Reactive Network coordinates the authenticated callback. Unichain hosts the real PoolManager, auction, hook, controller, and reward vault. Before-swap validates the permit, and after-swap settles it against the resulting price.

### Slide 5: Proof and Impact (`1:19-1:42`)

**On screen:** Allocation metrics and the Alice/Bao split.

**Say:**

> The proof uses a real local v4 PoolManager path and a testnet deployment. The complete winning bid is indexed to eligible LP shares in constant time. In our demo, Alice receives point nine, Bao receives point six, and a late LP receives zero.

### Slide 6: From Proof to Protocol (`1:42-2:00`)

**On screen:** Live proof, next steps, and demo handoff.

**Say:**

> The current proof demonstrates the complete mechanism. Next, we would add commit-reveal bidding, production oracle adapters, and searcher pilots. For the remaining three minutes, I will run the market live from dislocation to LP payout.

## Three-Minute Walkthrough Script

### Scene 1: Establish the Baseline (`2:00-2:18`)

**Account:** Any account.

**Action:** Open `/demo`. Point at the pool price, `Awaiting shock`, and the LP snapshot.

**Say:**

> This console reads the deployed contracts on Base and Unichain. The observed v4 pool is trading near one, no correction window exists, and Alice and Bao already hold the LP shares in a sixty-forty split.

### Scene 2: Create the Dislocation (`2:18-2:35`)

**Account:** Source Operator on Base Sepolia.

**Action:** Click `Create 1.06 price shock` and approve the wallet transaction. Show the submitted-transaction notice.

**Say:**

> I now move the controlled Base Sepolia reference to one point zero six. That creates about six percent divergence, above the controller's one-percent threshold.

**Edit:** Cut the wait after the transaction is visible. Resume when the callback has opened a window.

### Scene 3: Show Reactive Coordination (`2:35-2:51`)

**Account:** Any account.

**Action:** Refresh the console. Point to reference price `1.06`, divergence, the bidding state, and `WindowOpened` in the event trace.

**Say:**

> Reactive observed the cross-chain signal and delivered an authenticated callback to Unichain. The controller has opened a thirty-second auction and locked the LP snapshot block.

### Scene 4: Create Bid Competition (`2:51-3:18`)

**Account:** Searcher A in the terminal, then Searcher B in MetaMask.

**Action:** Submit Searcher A's `1.0 dWETH` bid from the prepared terminal. Immediately connect Searcher B and click `Approve + bid 1.5`. Refresh the console.

**Say:**

> Searcher A first bids one dWETH. Searcher B raises that to one point five and becomes the leader. Instead of racing for gas, searchers compete directly on the value returned to liquidity providers.

**Prepared terminal commands:**

```bash
export WINDOW_ID=$(cast call "$CONTROLLER" "activeWindowForPool(bytes32)(uint256)" "$POOL_ID" --rpc-url "$UNICHAIN_RPC_URL")
cast send "$BID_TOKEN" "approve(address,uint256)" "$AUCTION" 1000000000000000000 --rpc-url "$UNICHAIN_RPC_URL" --private-key "$SEARCHER_A_PRIVATE_KEY"
cast send "$AUCTION" "bid(uint256,uint256)" "$WINDOW_ID" 1000000000000000000 --rpc-url "$UNICHAIN_RPC_URL" --private-key "$SEARCHER_A_PRIVATE_KEY"
```

**Edit:** If needed, cut the remainder of the thirty-second auction deadline.

### Scene 5: Finalize and Execute (`3:18-3:48`)

**Account:** Searcher B on Unichain Sepolia.

**Action:** Click `Finalize auction`, then click `Execute v4 permit` after finalization confirms. Show `PermitConsumed`, `WinningBidReleased`, and `RewardAllocated`.

**Say:**

> After the deadline, anyone can finalize. Searcher B receives a short-lived permit bound to the winner, direction, input, nonce, deadline, and price guard. The swap executes through the real v4 unlock path, and the hook consumes the permit only after validating the result.

### Scene 6: Prove Replay Protection (`3:48-4:03`)

**Account:** Keep Searcher B connected.

**Action:** Click `Attack: repeat permit`. Show the rejection notice.

**Say:**

> Repeating the exact same correction fails. The right is single-use and enforced by the hook, not by this interface.

### Scene 7: Show LP Revenue (`4:03-4:32`)

**Account:** Switch to Alice on Unichain Sepolia.

**Action:** Point to the Snapshot Ledger, then click `Claim my indexed reward`. Show the successful claim or `RewardClaimed` event.

**Say:**

> The complete one-point-five dWETH winning bid is now LP revenue. Alice's historical sixty-percent share earns point nine, Bao's forty percent earns point six, and liquidity arriving after the snapshot earns nothing. Alice can claim without looping over every LP.

### Scene 8: Verifiable Close (`4:32-5:00`)

**Account:** Any account.

**Action:** Scroll through the event trace. Finish on the completed-window state or the landing-page impact section.

**Say:**

> Every transition shown here is testnet-verifiable: the source shock, Reactive callback, competitive bids, v4 permit consumption, payment release, and snapshot claims. Rebalance Rights does not block price correction. It converts searcher competition into sustainable LP revenue.

## Walkthrough Preflight

Run these read-only checks before recording:

```bash
cast call "$CONTROLLER" "activeWindowForPool(bytes32)(uint256)" "$POOL_ID" --rpc-url "$UNICHAIN_RPC_URL"
cast call "$CONTROLLER" "latestPoolPriceE18(bytes32)(uint160)" "$POOL_ID" --rpc-url "$UNICHAIN_RPC_URL"
cast call "$CONTROLLER" "expectedRvmId()(address)" --rpc-url "$UNICHAIN_RPC_URL"
cast wallet address --private-key "$REACTIVE_PRIVATE_KEY"
```

Expected conditions:

- Active window is `0`.
- Latest pool price is approximately `1e18`.
- `expectedRvmId` equals the Reactive deployer address.
- Searcher A owns at least `1 dWETH`.
- Searcher B owns at least `1.5 dWETH` and enough pool token1 to correct.
- MetaMask has Source Operator, Searcher B, and Alice imported and labeled.
- The frontend is already open and connected before screen recording begins.

## Delivery Notes

- Keep the cursor still while speaking, then point only at the value being discussed.
- Zoom the browser to make the lifecycle panel and event trace readable at video resolution.
- Keep wallet popups short; the contract-state change is more important than the confirmation dialog.
- Never display private keys or the terminal environment file.
- Do not call the controlled source a production oracle.
- Say "auction a bounded correction right," not "eliminate MEV."
- If Reactive delivery is slow, show the source transaction, cut the wait, and resume at `WindowOpened`.
