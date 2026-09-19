import { formatEther } from "viem";
import { nftMarketAbi } from "./abi.js";
import { marketAddress, publicClient, rpcUrl, wsUrl } from "./config.js";

function requireMarket() {
  if (!marketAddress) {
    throw new Error("请在 .env 中设置 NFT_MARKET_ADDRESS");
  }
  return marketAddress;
}

function printListed(log) {
  const { seller, tokenId, price } = log.args;
  console.log("—— 上架 Listed ——");
  console.log(`  seller : ${seller}`);
  console.log(`  tokenId: ${tokenId}`);
  console.log(`  price  : ${formatEther(price)} CAMP`);
  console.log(`  tx     : ${log.transactionHash}`);
  console.log(`  block  : ${log.blockNumber}`);
  console.log("");
}

function printBought(log) {
  const { buyer, seller, tokenId, price } = log.args;
  console.log("—— 购买 Bought ——");
  console.log(`  buyer  : ${buyer}`);
  console.log(`  seller : ${seller}`);
  console.log(`  tokenId: ${tokenId}`);
  console.log(`  price  : ${formatEther(price)} CAMP`);
  console.log(`  tx     : ${log.transactionHash}`);
  console.log(`  block  : ${log.blockNumber}`);
  console.log("");
}

function onLogs(logs) {
  for (const log of logs) {
    if (log.eventName === "Listed") printListed(log);
    if (log.eventName === "Bought") printBought(log);
  }
}

const address = requireMarket();

console.log("监听 NFTMarket 上架 / 购买事件");
console.log(`  market : ${address}`);
console.log(`  rpc    : ${wsUrl || rpcUrl}`);
console.log("等待链上交易...\n");

const unwatch = publicClient.watchContractEvent({
  address,
  abi: nftMarketAbi,
  onLogs,
  onError: (error) => {
    console.error("监听出错:", error.shortMessage || error.message);
  },
});

const shutdown = () => {
  unwatch();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
