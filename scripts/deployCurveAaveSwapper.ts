import { ethers } from "hardhat";

const AAVE_POOL = "0x445FE580eF8d70FF569aB36e80c647af338db351";

async function main() {
  const factory = await ethers.getContractFactory("CurveAaveSwapper");

  const swapper = await factory.deploy(AAVE_POOL);
  const deploy = await swapper.deployed();

  console.info(
    `CurveAaveSwapper deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
