import { ethers } from "hardhat";
import { sendTx } from "./utils";

const POLYGON_TOKEN_BRIDGE = "0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE";

const POLYGON = {
  tokenBridge: "0x5a58505a96D1dbf8dF91cB21B54419FC36e93fdE",
  inbox: "0xA0A8907fc581a087d07350a467C891279ca6E8A2",
  chainId: 5,
};

const CELO = {
  tokenBridge: "0x796dff6d74f3e27060b71255fe517bfb23c93eed",
  inbox: "0x1db30F32676168E765617BD90EBa29Df6c79c89E",
  chainId: 14,
};

async function main() {
  const factory = await ethers.getContractFactory("Outbox");
  const outbox = await factory.deploy();
  const deploy = await outbox.deployed();

  console.info(
    `Outbox deployed to ${deploy.address} in tx ${deploy.deployTransaction.hash}`
  );

  await sendTx(outbox.addInbox(POLYGON.chainId, POLYGON.inbox));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
