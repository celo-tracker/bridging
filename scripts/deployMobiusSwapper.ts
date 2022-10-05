import { ethers } from "hardhat";

const MOBIUS_USDCet_POOL = "0xC0BA93D4aaf90d39924402162EE4a213300d1d60";

async function main() {
  const factory = await ethers.getContractFactory("MobiusSwapper");

  const swapper = await factory.deploy(MOBIUS_USDCet_POOL);
  const deploy = await swapper.deployed();

  console.info(
    `MobiusSwapper deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
