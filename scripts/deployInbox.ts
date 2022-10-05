import { ethers } from "hardhat";

const POLYGON = {
  tokenBridge: "0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE",
};
const CELO = {
  tokenBridge: "0x796dff6d74f3e27060b71255fe517bfb23c93eed",
};

async function main() {
  const factory = await ethers.getContractFactory("Inbox");
  const inbox = await factory.deploy(POLYGON.tokenBridge);

  const deploy = await inbox.deployed();

  console.info(
    `Inbox deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
