"use client";

import { startTransition, useEffect, useState } from "react";
import Link from "next/link";
import styles from "./page.module.css";
import { createPublicClient, createWalletClient, custom, defineChain, formatEther, http, parseEventLogs, type Address } from "viem";
import { auctionAbi, controllerAbi, erc20Abi, referenceAbi, routerAbi, vaultAbi } from "@/lib/abi";
import { deployed, destinationRpc, sourceRpc, short, type Deployment } from "@/lib/contracts";

type Window = {
  referencePriceE18: bigint; openingPoolPriceE18: bigint; bidDeadline: bigint; executionDeadline: bigint;
  snapshotBlock: bigint; permitNonce: bigint; snapshotSupply: bigint; winningBid: bigint; maximumInput: bigint;
  winner: Address; increasePrice: boolean; state: number;
};
type Trace = { label: string; hash: string; block: bigint };
type LpRow = { label: string; shares: bigint; reward: bigint };
type Market = { pool?: bigint; reference?: bigint };

declare global { interface Window { ethereum?: { request(args: { method: string; params?: unknown[] }): Promise<unknown> } } }

const unichain = defineChain({ id: 1301, name: "Unichain Sepolia", nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 }, rpcUrls: { default: { http: [destinationRpc] } } });
const source = defineChain({ id: 84532, name: "Base Sepolia", nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 }, rpcUrls: { default: { http: [sourceRpc] } } });
const stateLabel = ["No window", "Bidding", "Permit live", "Correction seen", "Expired", "Closed"];
const price = (value?: bigint) => value === undefined ? "-" : (Number(value) / 1e18).toLocaleString(undefined, { maximumFractionDigits: 2 });
const MIN_SQRT_PRICE = 4_295_128_739n;
const MAX_SQRT_PRICE = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342n;

export default function ScenarioConsole() {
  const [contracts, setContracts] = useState<Deployment | null>(null);
  const [windowId, setWindowId] = useState<bigint>(0n);
  const [windowState, setWindowState] = useState<Window | null>(null);
  const [highBid, setHighBid] = useState<readonly [Address, bigint, boolean] | null>(null);
  const [traces, setTraces] = useState<Trace[]>([]);
  const [lpRows, setLpRows] = useState<LpRow[]>([]);
  const [market, setMarket] = useState<Market>({});
  const [wallet, setWallet] = useState<Address | null>(null);
  const [notice, setNotice] = useState("Loading deployment record...");
  const [busy, setBusy] = useState(false);

  useEffect(() => { void loadDeployment(); }, []);
  useEffect(() => {
    if (!deployed(contracts)) return;
    void refresh();
    const timer = window.setInterval(() => void refresh(), 10_000);
    return () => window.clearInterval(timer);
  }, [contracts]);

  async function loadDeployment() {
    const response = await fetch("/deployments/testnet.json", { cache: "no-store" });
    const record = await response.json() as Deployment;
    setContracts(record);
    setNotice(deployed(record) ? "Live reads enabled. Polling Unichain Sepolia." : "Addresses are placeholders. Deploy contracts, update deployments/testnet.json, then refresh.");
  }

  async function refresh() {
    if (!contracts || !deployed(contracts)) return;
      const client = createPublicClient({ chain: unichain, transport: http(destinationRpc) });
      const sourceClient = createPublicClient({ chain: source, transport: http(sourceRpc) });
    try {
      const [active, latest, poolPrice, referencePrice, events] = await Promise.all([
        client.readContract({ address: contracts.controller, abi: controllerAbi, functionName: "activeWindowForPool", args: [contracts.poolId] }),
        client.readContract({ address: contracts.controller, abi: controllerAbi, functionName: "nextWindowId" }),
        client.readContract({ address: contracts.controller, abi: controllerAbi, functionName: "latestPoolPriceE18", args: [contracts.poolId] }),
        sourceClient.readContract({ address: contracts.referenceMarket, abi: referenceAbi, functionName: "priceE18", args: [contracts.pairId] }),
        recentEvents(client)
      ]);
      setMarket({ pool: poolPrice, reference: referencePrice });
      setTraces(events);
      const selected = active !== 0n ? active : latest;
      setWindowId(selected);
      if (selected === 0n) { setWindowState(null); setHighBid(null); setLpRows([]); return; }
      const [nextWindow, bid] = await Promise.all([
        client.readContract({ address: contracts.controller, abi: controllerAbi, functionName: "getWindow", args: [selected] }),
        client.readContract({ address: contracts.auction, abi: auctionAbi, functionName: "highBid", args: [selected] })
      ]);
      const typedWindow = nextWindow as Window;
      const [aliceShares, baoShares, lateShares, reward] = await Promise.all([
        client.readContract({ address: contracts.vault, abi: vaultAbi, functionName: "balanceOfAt", args: [contracts.alice, typedWindow.snapshotBlock] }),
        client.readContract({ address: contracts.vault, abi: vaultAbi, functionName: "balanceOfAt", args: [contracts.bao, typedWindow.snapshotBlock] }),
        client.readContract({ address: contracts.vault, abi: vaultAbi, functionName: "balanceOfAt", args: [contracts.lateLp, typedWindow.snapshotBlock] }),
        client.readContract({ address: contracts.vault, abi: vaultAbi, functionName: "rewards", args: [selected] })
      ]);
      const rewardIndex = reward[0];
      setLpRows([
        { label: "Alice", shares: aliceShares, reward: aliceShares * rewardIndex / 1_000_000_000_000_000_000n },
        { label: "Bao", shares: baoShares, reward: baoShares * rewardIndex / 1_000_000_000_000_000_000n },
        { label: "Late LP", shares: lateShares, reward: lateShares * rewardIndex / 1_000_000_000_000_000_000n }
      ]);
      setWindowState(typedWindow);
      setHighBid(bid as readonly [Address, bigint, boolean]);
      setNotice("State updated from contract reads and events.");
    } catch (error) { setNotice(`Read failed: ${message(error)}`); }
  }

  async function recentEvents(client: ReturnType<typeof createPublicClient>): Promise<Trace[]> {
    if (!contracts) return [];
    const latest = await client.getBlockNumber();
    const fromBlock = latest > 8_000n ? latest - 8_000n : 0n;
    const [controllerLogs, auctionLogs, vaultLogs] = await Promise.all([
      client.getLogs({ address: contracts.controller, fromBlock, toBlock: latest }),
      client.getLogs({ address: contracts.auction, fromBlock, toBlock: latest }),
      client.getLogs({ address: contracts.vault, fromBlock, toBlock: latest })
    ]);
    const entries: Trace[] = [];
    for (const event of parseEventLogs({ abi: controllerAbi, logs: controllerLogs, strict: false })) entries.push({ label: event.eventName ?? "Controller event", hash: event.transactionHash ?? "0x", block: event.blockNumber ?? 0n });
    for (const event of parseEventLogs({ abi: auctionAbi, logs: auctionLogs, strict: false })) entries.push({ label: event.eventName ?? "Auction event", hash: event.transactionHash ?? "0x", block: event.blockNumber ?? 0n });
    for (const event of parseEventLogs({ abi: vaultAbi, logs: vaultLogs, strict: false })) entries.push({ label: event.eventName ?? "Vault event", hash: event.transactionHash ?? "0x", block: event.blockNumber ?? 0n });
    return entries.sort((a, b) => Number(b.block - a.block)).slice(0, 12);
  }

  async function connect() {
    if (!window.ethereum) { setNotice("No injected EVM wallet found."); return; }
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" }) as Address[];
    setWallet(accounts[0] ?? null);
  }

  async function submitDestination(action: "approveBid" | "bid" | "finalize" | "correct" | "claim" | "expired" | "repeat") {
    if (!contracts || !window.ethereum || !windowId) return;
    setBusy(true);
    try {
      const account = await accountFor(unichain);
      const client = createWalletClient({ account, chain: unichain, transport: custom(window.ethereum) });
      let hash: `0x${string}`;
      if (action === "approveBid") {
        hash = await client.writeContract({ address: contracts.bidToken, abi: erc20Abi, functionName: "approve", args: [contracts.auction, 1_500_000_000_000_000_000n] });
      } else if (action === "bid") {
        const amount = 1_500_000_000_000_000_000n;
        hash = await client.writeContract({ address: contracts.auction, abi: auctionAbi, functionName: "bid", args: [windowId, amount] });
      } else if (action === "finalize") hash = await client.writeContract({ address: contracts.controller, abi: controllerAbi, functionName: "finalizeWindow", args: [windowId] });
      else if (action === "claim") hash = await client.writeContract({ address: contracts.vault, abi: vaultAbi, functionName: "claim", args: [windowId] });
      else if (action === "expired") hash = await client.writeContract({ address: contracts.controller, abi: controllerAbi, functionName: "expireWindow", args: [windowId] });
      else {
        if (!windowState) throw new Error("No finalized permit to execute");
        const inputToken = windowState.increasePrice ? contracts.poolToken1 : contracts.poolToken0;
        const approval = await client.writeContract({ address: inputToken, abi: erc20Abi, functionName: "approve", args: [contracts.router, 5_000_000_000_000_000_000n] });
        await createPublicClient({ chain: unichain, transport: http(destinationRpc) }).waitForTransactionReceipt({ hash: approval });
        hash = await client.writeContract({
          address: contracts.router,
          abi: routerAbi,
          functionName: "swapWithPermit",
          args: [
            { currency0: contracts.poolToken0, currency1: contracts.poolToken1, fee: contracts.poolFee, tickSpacing: contracts.tickSpacing, hooks: contracts.hook },
            { zeroForOne: !windowState.increasePrice, amountSpecified: -5_000_000_000_000_000_000n, sqrtPriceLimitX96: windowState.increasePrice ? MAX_SQRT_PRICE - 1n : MIN_SQRT_PRICE + 1n },
            windowId,
            windowState.permitNonce
          ]
        });
      }
      setNotice(`${action} submitted: ${hash}`);
      await createPublicClient({ chain: unichain, transport: http(destinationRpc) }).waitForTransactionReceipt({ hash });
      await refresh();
    } catch (error) { setNotice(`${action} rejected: ${message(error)}`); }
    finally { setBusy(false); }
  }

  async function shock() {
    if (!contracts || !window.ethereum) return;
    setBusy(true);
    try {
      const account = await accountFor(source);
      const client = createWalletClient({ account, chain: source, transport: custom(window.ethereum) });
      const hash = await client.writeContract({ address: contracts.referenceMarket, abi: referenceAbi, functionName: "setPrice", args: [contracts.pairId, BigInt(contracts.shockPriceE18)] });
      await createPublicClient({ chain: source, transport: http(sourceRpc) }).waitForTransactionReceipt({ hash });
      setNotice(`Price shock submitted: ${hash}. Waiting for Reactive callback before bids can open.`);
    } catch (error) { setNotice(`Price shock rejected: ${message(error)}`); }
    finally { setBusy(false); }
  }

  async function runScenario() {
    await shock();
    startTransition(() => setNotice("Price shock submitted. The console polls for the authenticated Reactive callback; then bid, finalize, execute, and claim in order."));
  }

  async function accountFor(chain: { id: number; name: string }) {
    if (!window.ethereum) throw new Error("No injected wallet");
    let chainId = await window.ethereum.request({ method: "eth_chainId" }) as string;
    if (Number.parseInt(chainId, 16) !== chain.id) {
      await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: `0x${chain.id.toString(16)}` }] });
      chainId = await window.ethereum.request({ method: "eth_chainId" }) as string;
    }
    if (Number.parseInt(chainId, 16) !== chain.id) throw new Error(`Wallet did not switch to ${chain.name}`);
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" }) as Address[];
    if (!accounts[0]) throw new Error("Wallet did not return an account");
    return accounts[0];
  }

  const bidDeadline = windowState ? new Date(Number(windowState.bidDeadline) * 1000).toLocaleTimeString() : "-";
  const poolPrice = windowState?.openingPoolPriceE18 ?? market.pool;
  const referencePrice = windowState?.referencePriceE18 ?? market.reference;
  const difference = poolPrice !== undefined && referencePrice !== undefined ? (referencePrice > poolPrice ? referencePrice - poolPrice : poolPrice - referencePrice) : 0n;
  const divergence = poolPrice ? Number(difference * 10_000n / poolPrice) / 100 : 0;
  const chartWidth = Math.min(100, divergence);

  return <main className={styles.demo}>
    <header><div><p className="eyebrow">BASE SEPOLIA {"->"} REACTIVE LASNA {"->"} UNICHAIN SEPOLIA</p><h1>Rebalance <i>Rights</i></h1><p className="lede">Auction the stale-pool correction. Return the bid to liquidity that bore the dislocation.</p></div><div className="header-actions"><Link className="back-link" href="/">Project site</Link><button className="ghost" onClick={() => void refresh()}>Refresh</button><button onClick={() => void connect()}>{wallet ? short(wallet) : "Connect wallet"}</button></div></header>
    <section className={`status ${deployed(contracts) ? "live" : "waiting"}`}><b>{deployed(contracts) ? "LIVE CONTRACT READS" : "DEPLOYMENT REQUIRED"}</b><span>{notice}</span></section>
    <section className="thesis"><div><p className="eyebrow">LVR recapture</p><h2>LPs sell a single, bounded route back to market.</h2></div><div className="route"><span>Source</span><b>ReferencePriceUpdated</b><span>RSC</span><b>authenticated callback</b><span>Auction</span></div></section>
    <section className="metrics"><Metric label="Pool price" value={price(poolPrice)} /><Metric label="Reference price" value={price(referencePrice)} /><Metric label="Divergence" value={poolPrice && referencePrice ? `${divergence.toFixed(2)}%` : "-"} /><Metric label="Window" value={windowState ? stateLabel[windowState.state] : "Awaiting shock"} /></section>
    <section className="grid">
      <article className="panel price-panel"><PanelTitle eyebrow="Price divergence" value="100 bps trigger" /><div className="chart"><div className="threshold" /><div className="pool-line" style={{ width: "24%" }} /><div className="reference-line" style={{ width: `${24 + chartWidth}%` }} /><span className="pool-tag">pool {price(poolPrice)}</span><span className="reference-tag">reference {price(referencePrice)}</span></div><p>PoolManager sqrtPriceX96 is normalized onchain to priceE18 before comparison. The controlled source demonstrates mechanism behavior, not oracle quality.</p></article>
      <article className="panel auction-panel"><PanelTitle eyebrow="Correction right" value={windowState ? stateLabel[windowState.state] : "No active auction"} /><dl><div><dt>High bid</dt><dd>{highBid ? `${formatEther(highBid[1])} dWETH` : "-"}</dd></div><div><dt>Leader</dt><dd>{highBid ? short(highBid[0]) : "-"}</dd></div><div><dt>Bid deadline</dt><dd>{bidDeadline}</dd></div><div><dt>Permit limit</dt><dd>{windowState ? `${formatEther(windowState.maximumInput)} dWETH` : "-"}</dd></div></dl></article>
      <article className="panel lp-panel"><PanelTitle eyebrow="Snapshot ledger" value={windowState ? `block ${windowState.snapshotBlock}` : "No snapshot"} /><div className="split">{lpRows.length === 0 ? <div><span>Awaiting snapshot reads.</span></div> : lpRows.map((row) => <div className={row.label === "Late LP" ? "late" : ""} key={row.label}><b>{windowState?.snapshotSupply ? `${Number(row.shares * 100n / windowState.snapshotSupply)}%` : "0%"}</b><span>{row.label}: {formatEther(row.reward)} dWETH claimable</span></div>)}</div><button className="wide lime" disabled={busy || !windowId} onClick={() => void submitDestination("claim")}>Claim my indexed reward</button></article>
      <article className="panel trace-panel"><PanelTitle eyebrow="Reactive trace" value={`${traces.length} events`} /><ol>{traces.length === 0 ? <li className="empty">No destination events indexed yet.</li> : traces.map((trace, index) => <li key={`${trace.hash}-${index}`}><span>#{trace.block}</span><a href={`https://sepolia.uniscan.xyz/tx/${trace.hash}`} target="_blank" rel="noreferrer">{trace.label}</a></li>)}</ol></article>
    </section>
      <section className="controls panel"><PanelTitle eyebrow="Scenario controls" value="Transactions only, never local state" /><div className="control-grid"><button disabled={busy || !deployed(contracts)} onClick={() => void shock()}>1. Create {price(contracts ? BigInt(contracts.shockPriceE18) : undefined)} price shock</button><button disabled={busy || !deployed(contracts)} onClick={() => void submitDestination("approveBid")}>Preflight: approve 1.5 bid</button><button disabled={busy || !windowId} onClick={() => void submitDestination("bid")}>2. Bid 1.5</button><button disabled={busy || !windowId} onClick={() => void submitDestination("finalize")}>3. Finalize auction</button><button disabled={busy || !windowId} onClick={() => void submitDestination("correct")}>4. Execute v4 permit</button><button className="danger" disabled={busy || !windowId} onClick={() => void submitDestination("repeat")}>Attack: repeat permit</button><button className="danger" disabled={busy || !windowId} onClick={() => void submitDestination("claim")}>Attack: late/duplicate claim</button><button className="ghost" disabled={busy || !windowId} onClick={() => void submitDestination("expired")}>Expire + refund if overdue</button><button className="lime" disabled={busy || !deployed(contracts)} onClick={() => void runScenario()}>Start guided scenario</button></div></section>
    <footer>{["referenceMarket", "controller", "auction", "vault", "hook", "router", "rsc"].map((key) => <span key={key}>{key} <b>{short(contracts?.[key as keyof Deployment] as string)}</b></span>)}</footer>
  </main>;
}

function PanelTitle({ eyebrow, value }: { eyebrow: string; value: string }) { return <div className="panel-head"><p className="eyebrow">{eyebrow}</p><b>{value}</b></div>; }
function Metric({ label, value }: { label: string; value: string }) { return <article><p>{label}</p><strong>{value}</strong></article>; }
function message(error: unknown) { return error instanceof Error ? (error as Error & { shortMessage?: string }).shortMessage ?? error.message : "Unknown wallet or RPC error"; }
