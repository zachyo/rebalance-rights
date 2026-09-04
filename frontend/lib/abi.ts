export const controllerAbi = [
  { type: "function", name: "nextWindowId", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { type: "function", name: "activeWindowForPool", stateMutability: "view", inputs: [{ name: "", type: "bytes32" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "latestPoolPriceE18", stateMutability: "view", inputs: [{ name: "", type: "bytes32" }], outputs: [{ type: "uint160" }] },
  { type: "function", name: "finalizeWindow", stateMutability: "nonpayable", inputs: [{ name: "windowId", type: "uint256" }], outputs: [] },
  { type: "function", name: "expireWindow", stateMutability: "nonpayable", inputs: [{ name: "windowId", type: "uint256" }], outputs: [] },
  { type: "function", name: "getWindow", stateMutability: "view", inputs: [{ name: "windowId", type: "uint256" }], outputs: [{ type: "tuple", components: [
    { name: "poolId", type: "bytes32" }, { name: "referencePriceE18", type: "uint160" }, { name: "openingPoolPriceE18", type: "uint160" }, { name: "priceGuardE18", type: "uint160" }, { name: "referenceSequence", type: "uint64" }, { name: "openedAt", type: "uint64" }, { name: "bidDeadline", type: "uint64" }, { name: "executionDeadline", type: "uint64" }, { name: "snapshotBlock", type: "uint64" }, { name: "permitNonce", type: "uint64" }, { name: "snapshotSupply", type: "uint256" }, { name: "winningBid", type: "uint256" }, { name: "maximumInput", type: "uint256" }, { name: "winner", type: "address" }, { name: "increasePrice", type: "bool" }, { name: "state", type: "uint8" }
  ] }] },
  { type: "event", name: "WindowOpened", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "poolId", type: "bytes32" }, { indexed: false, name: "referencePriceE18", type: "uint160" }, { indexed: false, name: "poolPriceE18", type: "uint160" }, { indexed: false, name: "snapshotBlock", type: "uint64" }, { indexed: false, name: "increasePrice", type: "bool" }] },
  { type: "event", name: "WindowFinalized", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "winner", type: "address" }, { indexed: false, name: "winningBid", type: "uint256" }, { indexed: false, name: "permitNonce", type: "uint64" }] },
  { type: "event", name: "PermitConsumed", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "winner", type: "address" }, { indexed: false, name: "amountIn", type: "uint256" }, { indexed: false, name: "amountOut", type: "uint256" }] },
  { type: "event", name: "WindowCorrected", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "callbackNonce", type: "uint64" }] },
  { type: "event", name: "WindowExpired", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "bidder", type: "address" }, { indexed: false, name: "refundedBid", type: "uint256" }] }
] as const;

export const auctionAbi = [
  { type: "function", name: "bid", stateMutability: "nonpayable", inputs: [{ name: "windowId", type: "uint256" }, { name: "amount", type: "uint256" }], outputs: [] },
  { type: "function", name: "highBid", stateMutability: "view", inputs: [{ name: "", type: "uint256" }], outputs: [{ name: "bidder", type: "address" }, { name: "amount", type: "uint256" }, { name: "settled", type: "bool" }] },
  { type: "event", name: "BidPlaced", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "bidder", type: "address" }, { indexed: false, name: "amount", type: "uint256" }] },
  { type: "event", name: "WinningBidReleased", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "winner", type: "address" }, { indexed: false, name: "amount", type: "uint256" }] }
] as const;

export const vaultAbi = [
  { type: "function", name: "claim", stateMutability: "nonpayable", inputs: [{ name: "windowId", type: "uint256" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "balanceOfAt", stateMutability: "view", inputs: [{ name: "account", type: "address" }, { name: "blockNumber", type: "uint64" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "rewards", stateMutability: "view", inputs: [{ name: "", type: "uint256" }], outputs: [{ name: "index", type: "uint256" }, { name: "amount", type: "uint256" }, { name: "snapshotBlock", type: "uint64" }, { name: "allocated", type: "bool" }] },
  { type: "event", name: "RewardAllocated", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: false, name: "amount", type: "uint256" }, { indexed: false, name: "snapshotBlock", type: "uint64" }, { indexed: false, name: "snapshotSupply", type: "uint256" }] },
  { type: "event", name: "RewardClaimed", inputs: [{ indexed: true, name: "windowId", type: "uint256" }, { indexed: true, name: "lp", type: "address" }, { indexed: false, name: "amount", type: "uint256" }] }
] as const;

const poolKey = { name: "key", type: "tuple", components: [{ name: "currency0", type: "address" }, { name: "currency1", type: "address" }, { name: "fee", type: "uint24" }, { name: "tickSpacing", type: "int24" }, { name: "hooks", type: "address" }] } as const;
const swapParams = { name: "params", type: "tuple", components: [{ name: "zeroForOne", type: "bool" }, { name: "amountSpecified", type: "int256" }, { name: "sqrtPriceLimitX96", type: "uint160" }] } as const;
export const routerAbi = [{ type: "function", name: "swapWithPermit", stateMutability: "nonpayable", inputs: [poolKey, swapParams, { name: "windowId", type: "uint256" }, { name: "permitNonce", type: "uint64" }], outputs: [] }] as const;
export const erc20Abi = [{ type: "function", name: "approve", stateMutability: "nonpayable", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ type: "bool" }] }] as const;
export const referenceAbi = [
  { type: "function", name: "setPrice", stateMutability: "nonpayable", inputs: [{ name: "pairId", type: "bytes32" }, { name: "nextPriceE18", type: "uint160" }], outputs: [] },
  { type: "function", name: "priceE18", stateMutability: "view", inputs: [{ name: "", type: "bytes32" }], outputs: [{ type: "uint160" }] }
] as const;
