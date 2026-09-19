import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { formatEther, parseEther } from "viem";
import { erc20Abi, erc721Abi, nftMarketAbi } from "./abi.js";
import {
  marketAddress as envMarket,
  nftAddress as envNft,
  publicClient,
  tokenAddress as envToken,
  tokenHolderWallet,
  walletClientFromKey,
} from "./config.js";

const PRICE = parseEther("100");
const URI = "ipfs://viem-trade";
const root = path.dirname(fileURLToPath(import.meta.url));

function loadArtifact(contractName) {
  const artifactPath = path.resolve(
    root,
    `../forge_project/out/${contractName}.sol/${contractName}.json`,
  );
  const json = JSON.parse(readFileSync(artifactPath, "utf8"));
  return { abi: json.abi, bytecode: json.bytecode.object };
}

async function send(wallet, params) {
  const hash = await wallet.writeContract(params);
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  if (receipt.status !== "success") {
    throw new Error(`交易失败: ${hash}`);
  }
  return { hash, receipt };
}

const MIN_ETH = parseEther("0.05");

async function ensureEth(funder, account) {
  const balance = await publicClient.getBalance({ address: account.address });
  if (balance >= MIN_ETH) return;
  const hash = await funder.sendTransaction({
    to: account.address,
    value: parseEther("0.1"),
  });
  await publicClient.waitForTransactionReceipt({ hash });
  console.log(`fund ETH 0.1 -> ${account.address}  tx=${hash}`);
}

async function deployIfNeeded(seller) {
  if (envMarket) {
    const token = envToken || (await publicClient.readContract({
      address: envMarket,
      abi: nftMarketAbi,
      functionName: "paymentToken",
    }));
    const nft = envNft || (await publicClient.readContract({
      address: envMarket,
      abi: nftMarketAbi,
      functionName: "nft",
    }));
    return { market: envMarket, token, nft, deployed: false };
  }

  console.log("未配置 NFT_MARKET_ADDRESS，使用 forge 产物自动部署...");
  const tokenArt = loadArtifact("MyERC20");
  const nftArt = loadArtifact("MyERC721");
  const marketArt = loadArtifact("NFTMarket");

  const tokenHash = await seller.deployContract({
    abi: tokenArt.abi,
    bytecode: tokenArt.bytecode,
    args: ["Camp Token", "CAMP"],
  });
  const tokenReceipt = await publicClient.waitForTransactionReceipt({ hash: tokenHash });
  const token = tokenReceipt.contractAddress;

  const nftHash = await seller.deployContract({
    abi: nftArt.abi,
    bytecode: nftArt.bytecode,
  });
  const nftReceipt = await publicClient.waitForTransactionReceipt({ hash: nftHash });
  const nft = nftReceipt.contractAddress;

  const marketHash = await seller.deployContract({
    abi: marketArt.abi,
    bytecode: marketArt.bytecode,
    args: [token, nft],
  });
  const marketReceipt = await publicClient.waitForTransactionReceipt({ hash: marketHash });
  const market = marketReceipt.contractAddress;

  console.log(`MyERC20   ${token}`);
  console.log(`MyERC721  ${nft}`);
  console.log(`NFTMarket ${market}`);
  console.log("可将以上地址写入 .env 供 watch.js 使用\n");

  return { market, token, nft, deployed: true };
}

async function mintNft(seller, nft) {
  const { request, result } = await publicClient.simulateContract({
    address: nft,
    abi: erc721Abi,
    functionName: "mint",
    args: [seller.account.address, URI],
    account: seller.account,
  });
  const { hash } = await send(seller, request);
  console.log(`mint tokenId=${result}  tx=${hash}`);
  return result;
}

async function main() {
  const seller = walletClientFromKey(process.env.SELLER_PRIVATE_KEY);
  const buyer = walletClientFromKey(process.env.BUYER_PRIVATE_KEY);

  if (seller.account.address.toLowerCase() === buyer.account.address.toLowerCase()) {
    throw new Error("卖家和买家不能是同一个地址（合约禁止 self buy）");
  }

  const { market, token, nft } = await deployIfNeeded(seller);
  console.log(`seller ${seller.account.address}`);
  console.log(`buyer  ${buyer.account.address}`);
  console.log(`market ${market}\n`);

  await ensureEth(seller, buyer.account);

  const tokenId = await mintNft(seller, nft);

  await send(seller, {
    address: nft,
    abi: erc721Abi,
    functionName: "approve",
    args: [market, tokenId],
  });
  const listed = await send(seller, {
    address: market,
    abi: nftMarketAbi,
    functionName: "list",
    args: [tokenId, PRICE],
  });
  console.log(`list  tokenId=${tokenId} price=${formatEther(PRICE)} CAMP  tx=${listed.hash}`);

  const buyerBal = await publicClient.readContract({
    address: token,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [buyer.account.address],
  });
  if (buyerBal < PRICE) {
    const funder = tokenHolderWallet(seller);
    const funderBal = await publicClient.readContract({
      address: token,
      abi: erc20Abi,
      functionName: "balanceOf",
      args: [funder.account.address],
    });
    if (funderBal < PRICE) {
      throw new Error(
        `CAMP 不足：持币账户 ${funder.account.address} 余额 ${formatEther(funderBal)}，需要 ${formatEther(PRICE)}。请设置 TOKEN_HOLDER_PRIVATE_KEY 或 MNEMONIC（Forge 部署账户）。`,
      );
    }
    const funded = await send(funder, {
      address: token,
      abi: erc20Abi,
      functionName: "transfer",
      args: [buyer.account.address, PRICE],
    });
    console.log(
      `transfer ${formatEther(PRICE)} CAMP ${funder.account.address} -> buyer  tx=${funded.hash}`,
    );
  }

  await send(buyer, {
    address: token,
    abi: erc20Abi,
    functionName: "approve",
    args: [market, PRICE],
  });
  const bought = await send(buyer, {
    address: market,
    abi: nftMarketAbi,
    functionName: "buyNFT",
    args: [tokenId, PRICE],
  });
  console.log(`buyNFT tokenId=${tokenId}  tx=${bought.hash}`);

  const owner = await publicClient.readContract({
    address: nft,
    abi: erc721Abi,
    functionName: "ownerOf",
    args: [tokenId],
  });
  console.log(`\n完成：tokenId ${tokenId} 当前持有人 ${owner}`);
}

main().catch((error) => {
  console.error(error.shortMessage || error.message);
  process.exit(1);
});
