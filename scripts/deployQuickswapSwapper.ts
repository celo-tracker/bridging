import { ethers } from "hardhat";

const QUICKSWAP_ROUTER = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";

async function main() {
  const factory = await ethers.getContractFactory("QuickswapSwapper");

  const swapper = await factory.deploy(QUICKSWAP_ROUTER);
  const deploy = await swapper.deployed();

  console.info(
    `QuickswapSwapper deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
