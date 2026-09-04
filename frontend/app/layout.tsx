import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Rebalance Rights | Auction the Move",
  description: "A Uniswap v4 MEV auction hook that sells bounded stale-price correction rights and returns the winning bid to exposed liquidity providers."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
