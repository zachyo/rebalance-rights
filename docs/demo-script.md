# Demo Runbook

1. Open the frontend and point out the normalized pool price, configured reference shock, and 100 bps threshold. The deployed demo template initializes at approximately 1.00 and shocks to 1.06.
2. As the source operator, submit `MockReferenceMarket.setPrice(pairId, shockPriceE18)` from the frontend.
3. Show `ReferencePriceUpdated`, the RSC callback event, then `WindowOpened` on Unichain.
4. From two funded searchers, place a 1.0 and 1.5 dWETH bid. Explain that displaced collateral is a pull refund.
5. After the bid deadline, call `finalizeWindow`. Show the winner, input cap, direction, nonce, and execution deadline.
6. From the winner, call the live `UniswapV4RebalanceRouter.swapWithPermit` from the frontend. It submits a `PoolKey`, `SwapParams`, window ID, and permit nonce; show `PermitConsumed` and the RSC `markCorrected` callback.
7. Claim as Alice and Bao. The snapshot gives 0.9 / 0.6 dWETH from the 1.5 dWETH winning bid; a late LP receives zero.
8. Attempt a repeat permit transaction and a duplicate/late claim. Both revert. Optionally let a fresh permit expire and withdraw the full high-bid refund.

The console links destination transactions using Uniscan and polls state while callbacks are pending. Do not claim that a delayed testnet callback is instantaneous.
