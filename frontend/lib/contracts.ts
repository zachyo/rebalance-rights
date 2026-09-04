import type { Address } from "viem";

export type Deployment = {
  sourceChainId: number;
  destinationChainId: number;
  reactiveChainId: number;
  referenceMarket: Address;
  liquidityToken: Address;
  bidToken: Address;
  vault: Address;
  controller: Address;
  auction: Address;
  hook: Address;
  router: Address;
  rsc: Address;
  callbackProxy: Address;
  rvmId: Address;
  pairId: `0x${string}`;
  poolId: `0x${string}`;
  poolToken0: Address;
  poolToken1: Address;
  poolFee: number;
  tickSpacing: number;
  alice: Address;
  bao: Address;
  lateLp: Address;
  shockPriceE18: string;
};

export const zeroAddress = "0x0000000000000000000000000000000000000000" as Address;
export const deployed = (contracts: Deployment | null) => Boolean(contracts && contracts.controller !== zeroAddress);
export const short = (value?: string) => value && value !== zeroAddress ? `${value.slice(0, 6)}...${value.slice(-4)}` : "placeholder";
export const destinationRpc = process.env.NEXT_PUBLIC_UNICHAIN_RPC_URL ?? "https://sepolia.unichain.org";
export const sourceRpc = process.env.NEXT_PUBLIC_SOURCE_RPC_URL ?? "https://sepolia.base.org";
