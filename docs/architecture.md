# Architecture

Rebalance Rights makes one bounded stale-price correction an LP-owned asset. The source `MockReferenceMarket` emits a controlled reference-price change in `priceE18`. The v4 hook converts PoolManager `sqrtPriceX96` to the same `priceE18` representation before emitting `PoolObserved`. `RebalanceRSC` watches both events and opens an authenticated auction callback once divergence reaches 100 bps.

```text
MockReferenceMarket -> RebalanceRSC -> Callback Proxy -> RebalanceController
                                                     -> RebalanceAuction
Winner -> RebalanceRouter -> RebalanceRightsHook -> controller.consumePermit
Auction escrow -> LpRewardVault snapshot reward index -> LP pull claims
```

## Canonical scenario

| Input | Value |
| --- | ---: |
| Initial pool/reference price | 2,000 |
| Reference shock | 2,120 |
| Divergence | 600 bps |
| Threshold | 100 bps |
| Auction / execution duration | 10 / 15 minutes on testnet; 60 / 120 seconds in tests |
| LP shares before shock | Alice 60, Bao 40 |
| Searcher bids in lifecycle test | 1.0 and 1.5 dWETH |
| Winning bid allocation | Alice 0.9, Bao 0.6 dWETH |
| Late LP allocation | 0 |
| Maximum correction input | 10 dWETH |

The reward index is `winning bid * 1e18 / total shares at snapshot block`. Each claimant reads their checkpointed shares at that same block, so the distribution has no LP loop and late deposits cannot participate.

## State transitions

`Open -> Finalized -> Consumed -> Closed` is the successful lifecycle. `Open` with no bids or `Finalized` after its execution deadline can transition to `Expired`. Expiry credits a full pull refund to the high bidder; it does not allocate a reward to LPs.

The local hook adapter models the state machine for deterministic tests. The live route is the mined `UniswapV4RebalanceRightsHook`: it validates the permit in `beforeSwap`, computes normalized pool price and consumes the permit in `afterSwap`, and is reached only through the v4 unlock-callback router. All economic enforcement, escrow, callback authentication, and reward allocation are chain-agnostic and covered by both deterministic and real-PoolManager tests.
