import { ethers } from "hardhat";

async function main() {
  const factory = await ethers.getContractFactory("PolygonStablecoinSwapper");

  const swapper = await factory.deploy(
    "0x44e3a52057b47f97557eD3D66B6503B236b2460B", // usdcSwapper
    "0x83C1Aa141F2186867e3700be09205692EC7FdbCA", // stablecoinSwapper
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", // usdcAddress
    "0x4318cb63a2b8edf2de971e2f17f77097e499459d" // usdcetAddress
  );
  const deploy = await swapper.deployed();

  console.info(
    `PolygonStablecoinSwapper deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
