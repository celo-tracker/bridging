import { ethers } from "hardhat";
import { sendTx } from "./utils";

const POLYGON = {
  tokenBridge: "0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE",
  inbox: "0x82852E474556965B5e76bCdAe158EB9fb17c5c6e",
  chainId: 5,
};

const CELO = {
  tokenBridge: "0x796dff6d74f3e27060b71255fe517bfb23c93eed",
  inbox: "0xD39a370B582f3B0163Ffe9a7Acc319856D2f5089",
  chainId: 14,
};

const DESTINATION_CHAIN = CELO

async function main() {
  const factory = await ethers.getContractFactory("Outbox");
  const outbox = await factory.deploy();
  const deploy = await outbox.deployed();

  console.info(
    `Outbox deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );

  await sendTx(outbox.addInbox(DESTINATION_CHAIN.chainId, DESTINATION_CHAIN.inbox));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
