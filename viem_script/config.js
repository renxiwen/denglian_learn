import path from "node:path";
import { fileURLToPath } from "node:url";
import { config as loadEnv } from "dotenv";
import {
  createPublicClient,
  createWalletClient,
  defineChain,
  http,
  webSocket,
} from "viem";
import { mnemonicToAccount, privateKeyToAccount } from "viem/accounts";
import { foundry, sepolia } from "viem/chains";

const here = path.dirname(fileURLToPath(import.meta.url));
loadEnv({ path: path.resolve(here, ".env") });
loadEnv({ path: path.resolve(here, "../forge_project/.env") });

export const rpcUrl = process.env.RPC_URL || "http://127.0.0.1:8545";
export const wsUrl = process.env.WS_URL || "";
export const chainId = Number(process.env.CHAIN_ID || 31337);

const chainById = {
  31337: foundry,
  11155111: sepolia,
};

export const chain =
  chainById[chainId] ||
  defineChain({
    id: chainId,
    name: `chain-${chainId}`,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: { default: { http: [rpcUrl] } },
  });

export const publicClient = createPublicClient({
  chain,
  transport: wsUrl ? webSocket(wsUrl) : http(rpcUrl),
});

export function walletClientFromKey(privateKey) {
  if (!privateKey) {
    throw new Error("缺少私钥：请在 .env 中设置 SELLER_PRIVATE_KEY / BUYER_PRIVATE_KEY");
  }
  const account = privateKeyToAccount(privateKey);
  return createWalletClient({
    account,
    chain,
    transport: http(rpcUrl),
  });
}

export function walletClientFromMnemonic(mnemonic, addressIndex = 0) {
  const account = mnemonicToAccount(mnemonic, { addressIndex });
  return createWalletClient({
    account,
    chain,
    transport: http(rpcUrl),
  });
}

/** CAMP 在 constructor 里铸给部署者。优先用 TOKEN_HOLDER / forge PRIVATE_KEY / MNEMONIC。 */
export function tokenHolderWallet(fallbackWallet) {
  const key = process.env.TOKEN_HOLDER_PRIVATE_KEY || process.env.PRIVATE_KEY;
  if (key) return walletClientFromKey(key);
  if (process.env.MNEMONIC) {
    return walletClientFromMnemonic(process.env.MNEMONIC, 0);
  }
  return fallbackWallet;
}

export const marketAddress = process.env.NFT_MARKET_ADDRESS;
export const tokenAddress = process.env.TOKEN_ADDRESS;
export const nftAddress = process.env.NFT_ADDRESS;
