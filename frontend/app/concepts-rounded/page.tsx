import Link from "next/link";
import styles from "./page.module.css";

const steps = [
  ["01", "Detect", "A reference move exposes a stale pool."],
  ["02", "Auction", "Searchers price the correction right."],
  ["03", "Correct", "The hook enforces one bounded swap."],
  ["04", "Return", "The bid flows to snapshot LPs."]
];

export default function RoundedConceptsPage() {
  return <div className={styles.gallery}>
    <header className={styles.intro}>
      <div><span>DESIGN STUDY / ROUND TWO</span><h1>Soft shapes.<br/>Serious mechanism.</h1></div>
      <div className={styles.introCopy}><p>Three bold directions using rounded cards, pill navigation, layered surfaces, and more approachable protocol storytelling.</p><nav><a href="#orbit">04 Orbit</a><a href="#garden">05 Liquidity Garden</a><a href="#cloud">06 Auction Cloud</a></nav></div>
    </header>

    <section className={`${styles.concept} ${styles.orbit}`} id="orbit">
      <nav className={styles.orbitNav}><b><i /> Rebalance Rights</b><div><a href="#orbitFlow">How it works</a><a href="#orbitImpact">Impact</a><Link href="/demo">Launch app <span>↗</span></Link></div></nav>
      <div className={styles.orbitHero}>
        <div className={styles.orbitCopy}><span className={styles.pill}>MEV AUCTION HOOK · UNISWAP V4</span><h2>Turn stale-price<br/>MEV into <i>LP yield.</i></h2><p>One corrective swap becomes a market. Searchers bid for access, the hook protects execution, and exposed liquidity receives the proceeds.</p><div className={styles.actions}><Link href="/demo">Run the live demo</Link><a href="#orbitFlow">Explore the mechanism ↓</a></div></div>
        <div className={styles.orbitVisual}>
          <div className={styles.glow} />
          <div className={styles.priceCard}><span>PRICE DISLOCATION</span><b>+6.01%</b><small>Threshold breached</small></div>
          <div className={styles.bidCard}><span>WINNING RIGHT</span><b>1.50 <small>dWETH</small></b><div><i style={{width: "60%"}} /><i style={{width: "40%"}} /></div></div>
          <div className={styles.routeChip}>Base <b>→</b> Reactive <b>→</b> Unichain</div>
        </div>
      </div>
      <div className={styles.orbitFlow} id="orbitFlow">{steps.map(([number, title, text]) => <article key={title}><span>{number}</span><h3>{title}</h3><p>{text}</p></article>)}</div>
      <p className={styles.label}>04 / ORBIT: polished fintech, dimensional gradients, product-led and broadly accessible.</p>
    </section>

    <section className={`${styles.concept} ${styles.garden}`} id="garden">
      <nav className={styles.gardenNav}><b>rebalance<span>rights</span></b><div><a href="#gardenStory">Our thesis</a><a href="#gardenImpact">Impact</a><Link href="/demo">Enter the app</Link></div></nav>
      <div className={styles.gardenHero}>
        <div className={styles.gardenCopy}><span>BUILT FOR SUSTAINABLE LIQUIDITY</span><h2>Let liquidity<br/><i>keep more</i> of<br/>what it creates.</h2><p>Rebalance Rights redirects the value around stale-pool correction to the LPs who carried the risk.</p><Link href="/demo">See the mechanism in action <b>→</b></Link></div>
        <div className={styles.gardenScene}>
          <div className={styles.sun}>1.50<span>dWETH returned</span></div>
          <div className={styles.leafOne}>60%<span>Alice</span></div><div className={styles.leafTwo}>40%<span>Bao</span></div>
          <div className={styles.ground}><span>PRE-SHOCK LP SNAPSHOT</span></div>
        </div>
      </div>
      <div className={styles.gardenStory} id="gardenStory"><article><span>THE LEAK</span><h3>Price correction extracts value from passive liquidity.</h3></article><article><span>THE LOOP</span><h3>Competition funds the liquidity that enabled it.</h3></article><article><span>THE PROTECTION</span><h3>Late LPs cannot harvest historical exposure.</h3></article></div>
      <p className={styles.label}>05 / LIQUIDITY GARDEN: warm, optimistic, sustainability-led, human rather than infrastructural.</p>
    </section>

    <section className={`${styles.concept} ${styles.cloud}`} id="cloud">
      <nav className={styles.cloudNav}><b>RR<span>°</span></b><div><a href="#cloudMarket">Market</a><a href="#cloudBuild">Build</a><Link href="/demo">Launch app ↗</Link></div></nav>
      <div className={styles.cloudHero}>
        <div><span className={styles.cloudPill}>UHI10 · MEV PROTECTION</span><h2>AUCTION<br/>THE <i>MOVE.</i></h2><p>Correction rights for Uniswap v4.<br/>Bounded for searchers. Productive for LPs.</p></div>
        <div className={styles.bubbleMarket} id="cloudMarket"><div className={styles.poolBubble}><small>POOL</small><b>0.9999</b></div><div className={styles.refBubble}><small>REFERENCE</small><b>1.0600</b></div><div className={styles.mevBubble}><small>CAPTURED</small><b>1.50</b><span>dWETH</span></div><div className={styles.arrowBubble}>↘</div></div>
      </div>
      <div className={styles.cloudRail} id="cloudBuild">{steps.map(([number, title]) => <div key={title}><span>{number}</span><b>{title}</b></div>)}</div>
      <div className={styles.cloudBottom}><h3>A tiny market at the exact moment liquidity needs protection.</h3><Link href="/demo">OPEN DEMO <span>→</span></Link></div>
      <p className={styles.label}>06 / AUCTION CLOUD: playful, spatial, highly memorable, with oversized bubbles and minimal copy.</p>
    </section>
  </div>;
}
