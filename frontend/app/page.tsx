import Link from "next/link";
import styles from "./page.module.css";

const mechanism = [
  { number: "01", title: "Detect", text: "Reactive observes a reference-price move and a stale Uniswap v4 pool." },
  { number: "02", title: "Auction", text: "Searchers compete for one winner-bound correction permit." },
  { number: "03", title: "Correct", text: "The hook enforces direction, input cap, deadline, and price guard." },
  { number: "04", title: "Return", text: "The winning bid is allocated to the LP snapshot that bore the risk." }
];

const integrations = [
  { mark: "UNI", name: "Uniswap v4", role: "Execution layer", text: "beforeSwap validates the correction right. afterSwap settles it against the resulting pool price." },
  { mark: "RN", name: "Reactive Network", role: "Coordination layer", text: "Cross-chain event detection opens and closes the auction through authenticated callbacks." },
  { mark: "BASE", name: "Base Sepolia", role: "Reference source", text: "A controlled source market produces the demo price event without claiming production oracle quality." },
  { mark: "UL2", name: "Unichain", role: "Settlement layer", text: "The pool, auction, hook, reward vault, and LP claims settle on a liquidity-focused L2." }
];

export default function HomePage() {
  return <div className={styles.site}>
    <header className={styles.navWrap}>
      <nav className={styles.nav}>
        <Link className={styles.brand} href="/"><span>RR</span><i>°</i><b>Rebalance Rights</b></Link>
        <div className={styles.navLinks}><a href="#problem">Problem</a><a href="#mechanism">Mechanism</a><a href="#impact">Impact</a><a href="#build">Build</a></div>
        <Link className={styles.launch} href="/demo">Launch app <span>↗</span></Link>
      </nav>
    </header>

    <main>
      <section className={styles.hero}>
        <div className={styles.heroCopy}>
          <span className={styles.eyebrow}>UHI10 · SUSTAINABLE LIQUIDITY · MEV AUCTION HOOK</span>
          <h1>AUCTION<br/>THE <i>MOVE.</i></h1>
          <p>Rebalance Rights sells one bounded stale-pool correction and returns the winning bid to the liquidity that made the opportunity possible.</p>
          <div className={styles.heroActions}><Link href="/demo">Run the live demo <span>→</span></Link><a href="#mechanism">See how it works</a></div>
        </div>
        <div className={styles.marketCloud} aria-label="Illustration of stale-price value returning to liquidity providers">
          <div className={styles.poolBubble}><small>POOL</small><b>0.9999</b><span>STALE</span></div>
          <div className={styles.referenceBubble}><small>REFERENCE</small><b>1.0600</b><span>LIVE</span></div>
          <div className={styles.captureBubble}><small>CAPTURED FOR LPs</small><b>1.50</b><span>dWETH</span></div>
          <div className={styles.routeBubble}>Base<br/><b>↓</b><br/>Reactive<br/><b>↓</b><br/>Unichain</div>
          <div className={styles.arrowBubble}>↘</div>
        </div>
      </section>

      <section className={styles.signalRail}>
        <div><span>DISLOCATION</span><b>+6.01%</b></div><div><span>AUCTION WINNER</span><b>Searcher B</b></div><div><span>LP RECAPTURE</span><b>1.50 dWETH</b></div><div><span>LATE LP SHARE</span><b>0%</b></div>
      </section>

      <section className={styles.problem} id="problem">
        <div className={styles.sectionTitle}><span>01 / PROBLEM + BACKGROUND</span><h2>Arbitrage repairs prices.<br/><i>Liquidity pays the bill.</i></h2></div>
        <div className={styles.problemGrid}>
          <article className={styles.problemPrimary}><span>THE LEAK</span><h3>A stale AMM price creates a valuable correction opportunity.</h3><p>When an external market moves first, arbitrageurs trade against the lagging pool. The correction keeps markets efficient, but its value is extracted from LP inventory as loss-versus-rebalancing.</p><div className={styles.miniFlow}><b>External move</b><i>→</i><b>Stale pool</b><i>→</i><b>Searcher value</b></div></article>
          <article className={styles.problemQuote}><span>THE QUESTION</span><blockquote>What if LPs could sell access to the correction before it happens?</blockquote></article>
          <article className={styles.problemAnswer}><span>OUR ANSWER</span><b>Make the correction right an auctioned, enforceable asset.</b><p>Preserve permissionless price discovery while redirecting competition toward sustainable liquidity.</p></article>
        </div>
      </section>

      <section className={styles.mechanism} id="mechanism">
        <div className={styles.sectionTitle}><span>02 / THE MECHANISM</span><h2>One event. One right.<br/><i>One accountable route.</i></h2></div>
        <div className={styles.mechanismGrid}>{mechanism.map((step) => <article key={step.number}><span>{step.number}</span><div className={styles.stepOrb}>{step.title.slice(0, 1)}</div><h3>{step.title}</h3><p>{step.text}</p></article>)}</div>
        <div className={styles.proofBar}><div><span>PROOF OF EXECUTION</span><b>Real PoolManager integration</b></div><div><span>PERMIT BOUNDS</span><b>Winner · nonce · direction · input · deadline · price</b></div><Link href="/demo">Inspect the demo <span>→</span></Link></div>
      </section>

      <section className={styles.impact} id="impact">
        <div className={styles.impactLead}><span>03 / IMPACT</span><h2>MEV competition becomes an LP revenue source.</h2><p>Rebalance Rights does not try to eliminate arbitrage. It creates a market around a specific corrective action, making some of its value available to the liquidity that absorbed the dislocation.</p></div>
        <div className={styles.impactCloud}>
          <div className={styles.bigImpact}><b>100%</b><span>of the winning bid allocated to eligible LP shares</span></div>
          <div className={styles.impactOne}><b>O(1)</b><span>reward allocation without iterating over LPs</span></div>
          <div className={styles.impactTwo}><b>1×</b><span>single-use correction permit</span></div>
          <div className={styles.impactThree}><b>0%</b><span>for liquidity arriving after the snapshot</span></div>
        </div>
      </section>

      <section className={styles.theme}>
        <div className={styles.themeHeader}><span>04 / UHI10 THEME ALIGNMENT</span><h2>Built for sustainable liquidity<br/>and MEV protection.</h2></div>
        <div className={styles.themeGrid}>
          <article><b>MEV AUCTION HOOK</b><p>Searchers bid onchain for an exclusive, bounded correction route.</p><span>CORE CATEGORY</span></article>
          <article><b>FEE-REBATE ECONOMICS</b><p>Auction proceeds function as a market-priced rebate to exposed liquidity.</p><span>LP SUSTAINABILITY</span></article>
          <article><b>HYBRID ROUTING</b><p>Reactive coordinates cross-chain signals while v4 enforces local execution.</p><span>CROSS-CHAIN DESIGN</span></article>
          <article><b>MEV PROTECTION</b><p>Winner binding and one-time permits stop identity spoofing and route reuse.</p><span>ENFORCED ONCHAIN</span></article>
        </div>
      </section>

      <section className={styles.partners} id="build">
        <div className={styles.sectionTitle}><span>05 / PARTNER INTEGRATIONS</span><h2>A small market,<br/><i>composed across chains.</i></h2></div>
        <div className={styles.partnerGrid}>{integrations.map((item) => <article key={item.name}><div className={styles.partnerMark}>{item.mark}</div><span>{item.role}</span><h3>{item.name}</h3><p>{item.text}</p></article>)}</div>
      </section>

      <section className={styles.reality}>
        <article className={styles.challenges}><span>06 / CHALLENGES</span><h2>What we do not hide.</h2><ul><li>Reactive delivery introduces latency before the auction opens.</li><li>Open bids can be copied or incrementally front-run.</li><li>A production deployment requires robust reference pricing.</li><li>Real profitability and auction equilibrium require market testing.</li></ul></article>
        <article className={styles.future}><span>07 / FUTURE PLANS + SUPPORT</span><h2>From proof to protocol.</h2><div><b>Commit-reveal auctions</b><p>Reduce bid copying while preserving price competition.</p></div><div><b>Production oracle adapters</b><p>Support trusted feeds and multi-market validation.</p></div><div><b>LP-token integrations</b><p>Snapshot real position ownership across supported pools.</p></div><div><b>We are looking for</b><p>Searcher partners, LP feedback, and testnet liquidity experiments.</p></div></article>
      </section>

      <section className={styles.finalCta}>
        <div><span>SEE THE FULL LIFECYCLE</span><h2>Move the price.<br/>Auction the right.<br/><i>Pay liquidity back.</i></h2></div>
        <Link href="/demo"><span>LAUNCH<br/>DEMO</span><b>↗</b></Link>
      </section>
    </main>

    <footer className={styles.footer}><Link className={styles.brand} href="/"><span>RR</span><i>°</i><b>Rebalance Rights</b></Link><p>Built for UHI10 · Sustainable Liquidity and MEV Protection</p><div><a href="#build">Architecture ↑</a><Link href="/demo">Demo ↗</Link></div></footer>
  </div>;
}
