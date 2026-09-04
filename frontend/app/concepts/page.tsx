import Link from "next/link";
import styles from "./page.module.css";

const flow = ["Dislocation detected", "Right auctioned", "Bounded swap", "LPs paid"];

export default function ConceptsPage() {
  return <div className={styles.gallery}>
    <header className={styles.picker}>
      <div><span>REBALANCE RIGHTS / DESIGN STUDY</span><h1>Choose a visual direction</h1></div>
      <nav><a href="#observatory">01 Observatory</a><a href="#control-room">02 Control Room</a><a href="#exchange">03 Rights Exchange</a></nav>
      <p>These are visual prototypes, not the final information architecture. Each can support Problem, Impact, Challenges, Integrations, Future Plans, and the existing demo console.</p>
    </header>

    <section className={`${styles.concept} ${styles.observatory}`} id="observatory">
      <nav className={styles.obsNav}><b>RR.</b><div><a href="#obsProblem">Thesis</a><a href="#obsMechanism">Mechanism</a><Link href="/demo">Launch app <span>↗</span></Link></div></nav>
      <div className={styles.obsHero}>
        <p className={styles.kicker}>UHI10 / Sustainable Liquidity / MEV Auction Hook</p>
        <h2>Make price correction<br/><i>pay liquidity back.</i></h2>
        <div className={styles.obsIntro}><p>Rebalance Rights auctions one bounded stale-pool correction and routes the winning bid to the LPs who bore the dislocation.</p><span>01 / 03<br/>PROTOCOL OBSERVATORY</span></div>
      </div>
      <div className={styles.obsTicker}><span>REFERENCE <b>1.0600</b></span><span>POOL <b>0.9999</b></span><span>DIVERGENCE <b>+6.01%</b></span><span>LP RECAPTURE <b>1.50 dWETH</b></span></div>
      <div className={styles.obsGrid} id="obsProblem">
        <article><small>THE PROBLEM</small><h3>Stale pools leak value at the moment liquidity is most exposed.</h3></article>
        <article><small>THE INTERVENTION</small><p>Searchers compete for a winner-bound, single-use correction permit. Competition prices the opportunity before execution.</p></article>
        <article><small>THE OUTCOME</small><p>Winning collateral is allocated to a historical LP snapshot. Late liquidity cannot capture rewards.</p></article>
      </div>
      <div className={styles.obsFlow} id="obsMechanism">{flow.map((item, index) => <div key={item}><b>0{index + 1}</b><span>{item}</span></div>)}</div>
      <p className={styles.caption}>Direction 01: premium editorial, research-led, calm and credible. Best for explaining a new economic primitive.</p>
    </section>

    <section className={`${styles.concept} ${styles.control}`} id="control-room">
      <nav className={styles.controlNav}><div><i /> REBALANCE_RIGHTS</div><span>UNICHAIN SEPOLIA · SYSTEM ONLINE</span><Link href="/demo">[ LAUNCH_APP ]</Link></nav>
      <div className={styles.controlGrid}>
        <div className={styles.controlHero}>
          <span className={styles.terminal}>$ protect --liquidity --capture-mev</span>
          <h2>THE POOL MOVED.<br/><strong>WHO GETS PAID?</strong></h2>
          <p>Searchers bid for correction rights. The hook enforces the winner. LPs collect the auction.</p>
          <Link className={styles.controlCta} href="/demo">OPEN LIVE CONSOLE <b>→</b></Link>
        </div>
        <aside className={styles.radar} aria-label="Price divergence radar"><div className={styles.radarRing}><div><b>6.01%</b><span>DISLOCATION</span></div></div><p><i /> THRESHOLD BREACHED</p></aside>
        <div className={styles.telemetry}><span>POOL_PRICE</span><b>0.9999</b><em>STALE</em></div>
        <div className={styles.telemetry}><span>REFERENCE</span><b>1.0600</b><em>LIVE</em></div>
        <div className={styles.telemetry}><span>TOP_BID</span><b>1.50</b><em>dWETH</em></div>
      </div>
      <div className={styles.controlFlow}>{flow.map((item, index) => <div key={item}><span>EVENT_0{index + 1}</span><b>{item.toUpperCase()}</b><i>{index < 3 ? "PROCESSING →" : "SETTLED ✓"}</i></div>)}</div>
      <p className={styles.caption}>Direction 02: technical, kinetic, event-driven. Best for making Reactive and onchain enforcement feel immediate.</p>
    </section>

    <section className={`${styles.concept} ${styles.exchange}`} id="exchange">
      <nav className={styles.exchangeNav}><b>REBALANCE<br/>RIGHTS®</b><div><span>PROTOCOL</span><span>IMPACT</span><span>BUILD</span></div><Link href="/demo">LAUNCH APP ↗</Link></nav>
      <div className={styles.exchangeHero}>
        <div><p>MEV AUCTION HOOK / UNISWAP V4</p><h2>CORRECTION<br/>IS AN <i>ASSET.</i></h2></div>
        <aside><span>AUCTION 0001</span><b>1.50</b><small>dWETH / WINNING RIGHT</small><hr/><p>60% ALICE<br/>40% BAO<br/>0% LATE LP</p></aside>
      </div>
      <div className={styles.exchangeStatement}><p>01 / PROBLEM</p><h3>Arbitrage repairs prices.<br/>LPs currently send the value away for free.</h3><div><b>OUR MARKET</b><span>One correction<br/>One winner<br/>One LP snapshot</span></div></div>
      <div className={styles.exchangeMarquee}>SELL THE RIGHT · PROTECT THE ROUTE · RETURN THE BID · </div>
      <p className={styles.caption}>Direction 03: bold, commercial, auction-first. Best for selling impact quickly and producing memorable slides.</p>
    </section>
  </div>;
}
