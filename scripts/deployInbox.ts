import { ethers } from "hardhat";

const POLYGON = {
  tokenBridge: "0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE",
  quickswapSwapper: "0x44e3a52057b47f97557eD3D66B6503B236b2460B",
  USDCet: "0x4318cb63a2b8edf2de971e2f17f77097e499459d",
  USDC: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
};
const CELO = {
  tokenBridge: "0x796dff6d74f3e27060b71255fe517bfb23c93eed",
};

async function main() {
  await setSwapper("0xA0A8907fc581a087d07350a467C891279ca6E8A2");
  return;

  const factory = await ethers.getContractFactory("Inbox");
  const inbox = await factory.deploy(CELO.tokenBridge);

  const deploy = await inbox.deployed();

  console.info(
    `Inbox deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );

  await setSwapper(deploy.address);
}

async function setSwapper(inboxAddress: string) {
  const factory = await ethers.getContractFactory("Inbox");
  const inbox = factory.attach(inboxAddress);

  const tx = await inbox.addSwapper(
    POLYGON.USDCet,
    POLYGON.USDC,
    POLYGON.quickswapSwapper
  );
  const receipt = await tx.wait();
  console.log(receipt.transactionHash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
