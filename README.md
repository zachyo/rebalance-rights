# Rebalance Rights

Rebalance Rights turns an AMM price dislocation into a bounded auction. Searchers compete for a one-time correction permit; the winning bid is distributed to LPs who held shares before the window opened.

```text
Reference-price event -> Reactive RSC -> authenticated callback -> Unichain controller
                                                             |
Searcher bids -> auction -> winner permit -> correction -> LP reward vault
```

## Partner Integrations

Unichain Sepolia hosts the destination pool, hook, controller, auction, reward vault, and execution router. Reactive monitors reference-price and pool-observation events, detects threshold divergence, and sends authenticated callbacks that open and close the rebalance window on Unichain.

### Unichain

The destination contracts execute on Unichain Sepolia (chain ID `1301`).

- `contracts/script/DeployV4Destination.s.sol` deploys the controller, auction, reward vault, router, and mined hook against the Unichain PoolManager supplied through `POOL_MANAGER`.
- `contracts/src/v4/UniswapV4RebalanceRouter.sol` executes swaps through that PoolManager and binds the winning permit to the correction transaction.
- `contracts/src/hook/UniswapV4RebalanceRightsHook.sol` enforces the correction lifecycle and emits pool observations consumed by the RSC.
- `contracts/script/SetupV4Demo.s.sol` initializes the demo pool on Unichain; `contracts/script/ObservePool.s.sol` submits fresh on-chain pool observations.
- `frontend/app/demo/page.tsx` connects the demo console to chain `1301` and submits the live lifecycle transactions.

### Reactive

Reactive supplies the event-driven coordination between the reference market and the Unichain execution contracts.

- `contracts/src/reactive/RebalanceRSC.sol` extends `AbstractReactive` and subscribes to the source `ReferencePriceUpdated`, Unichain `PoolObserved`, `PermitConsumed`, and `WindowExpired` events in `subscribe()`.
- The same contract implements `react(IReactive.LogRecord)`, deduplicates logs, detects threshold divergence, and emits `Callback` payloads for `openWindow` and `markCorrected`.
- `contracts/script/DeployReactive.s.sol` deploys and funds the RSC; the deployment flow calls `subscribe()` after deployment.
- `contracts/src/core/RebalanceController.sol` authenticates the Reactive callback proxy, RVM identity, and callback nonce before opening or closing a window.
- `contracts/test/RebalanceRSCTest.t.sol` covers Reactive event matching and reference-sequence deduplication.

## Theme Alignment

Rebalance Rights addresses Sustainable Liquidity and MEV Protection through a MEV auction hook: instead of allowing value from a known pool imbalance to be captured privately, searchers compete publicly for the right to correct it and the winning bid returns value to affected LPs.

## Problem / Background

Liquidity providers can be harmed when a market moves and an AMM pool remains stale: arbitrage restores the price, but the resulting value extraction generally does not compensate the LPs exposed to the stale liquidity. Rebalance Rights makes this correction opportunity explicit, time-bounded, permissioned, and revenue-sharing.

## Repository Layout

- `contracts/src/core/`: controller, auction, and checkpointed LP reward vault.
- `contracts/src/reactive/`: Reactive smart contract.
- `contracts/src/hook/` and `contracts/src/v4/`: hook and execution router.
- `contracts/script/`: source, destination, Reactive, setup, and observation deployment scripts.
- `contracts/test/`: deterministic lifecycle and Reactive tests.
- `frontend/`: Next.js and viem demo console.
- `deployments/testnet.json`: current testnet deployment metadata.
- `docs/`: architecture, threat model, demo script, and thumbnail assets.

## Local Setup

Requirements: Foundry and Node.js 20+.

```bash
forge install foundry-rs/forge-std Reactive-Network/reactive-lib transmissions11/solmate Uniswap/v4-core Uniswap/v4-periphery Uniswap/v4-hooks-public
forge test
```

```bash
cd frontend
npm install
npm run dev
```

Copy `.env.example` to `.env` only for testnet deployment. Never commit the populated `.env` file.

## Testnet Demo

The testnet destination is Unichain Sepolia (`1301`) and the RSC runs on Reactive Lasna (`5318007`). Deployment and role configuration belong in `.env`; public deployment metadata belongs in both `deployments/testnet.json` and `frontend/public/deployments/testnet.json`.

Run the automated suite with:

```bash
forge test
```

Build the frontend with:

```bash
cd frontend
npm run build
```

For the recorded flow, see [`docs/demo-script.md`](docs/demo-script.md).

## Impact

The project converts a reactive arbitrage event into a transparent market for correction rights. It protects LP economics through pre-window share snapshots, preventing late depositors from claiming rewards, while preserving competition among searchers and enforcing one-time, price-guarded execution.

## Challenges

The hardest parts were safely coordinating cross-chain event delivery with local hook execution, authenticating callbacks with the Reactive callback proxy, RVM identity, and nonces, and enforcing the winning permit through the Uniswap v4 unlock-callback flow. The implementation also handles asynchronous event ordering, log deduplication, window expiry, and deterministic LP reward accounting.

## Future Plans / Support

We would like to validate the auction parameters under more realistic liquidity and volatility conditions, improve the reference-price inputs beyond the controlled demo market, and conduct a security review of the hook, callback, and permit paths. Support with production-grade oracle design, Unichain liquidity testing, MEV-market design, and security review would be especially valuable.

## Security Notes

The controller validates callback sender, RVM identity, and nonce. Correction permits validate the winner, nonce, direction, maximum input, deadline, price guard, and single use. Auction and reward payments use pull-based claims; LP rewards use share checkpoints instead of iterating over LPs. See [`docs/threat-model.md`](docs/threat-model.md) and [`docs/architecture.md`](docs/architecture.md) for details.
