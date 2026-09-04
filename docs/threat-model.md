# Threat Model And Prototype Limits

## Enforced in contracts

- `openWindow` and `markCorrected` require both the configured Callback Proxy sender and the expected RVM ID.
- Callback nonces are single-use across callback actions.
- Only one active window is allowed per pool.
- Bid collateral transfers before a bid is accepted; displaced bidders and expired winners withdraw through pull payments.
- Only the configured router can invoke the hook; the router passes its actual `msg.sender` as the proposed winner, and the controller checks it against the finalized permit.
- A permit checks winner, nonce, direction, maximum input, deadline, no price overshoot, and one-time use before escrow is released.
- LP reward allocation uses historical share checkpoints. Claims are pull payments, and no distribution loops over LPs.

## Explicit limitations

- `MockReferenceMarket` is an operator-controlled test input, not an oracle.
- The local hook is a deterministic v4 adapter, not a deployed mined v4 hook. Deploying to a real v4 pool requires the PoolManager integration described in the README.
- Open bids are visible and copyable. Commit-reveal is future work.
- Reactive delivery has latency. An ordinary arbitrageur may correct a pool before a window opens.
- The controlled scenario does not establish oracle quality, auction equilibrium, or real profitability.
