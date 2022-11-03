# Bridging contracts

This project contains contracts used to make bridging between networks simpler. It uses the Wormhole token bridge to send tokens between chains and swaps the bridge tokens for native tokens so the user never have to manipulate for bridge tokens.

For example, when bridging USDCet to Polygon the system can swap it for native USDC on Quickswap so that users don't have to deal with the bridge token.

## Wormhole

As mentioned, this uses Wormhole under the hood. Wormhole is a generic cross-chain messaging protocol. Anyone can call the Wormhole contract to emit a message. There are Guardians that are always listening to messages sent and have to sign them in order for the messages to be accepted in the destination chain. Guardians provide an API where the signed message is exposed so anyone can fetch them and relay them to the destination.

On top of the generic messaging system a token bridge was built by the team called Portal. This simply sends a message with a specific format and new tokens are minted or released in the destination chain. It also allows appending a `payload` that can have any information we want (it's just a `bytes` field).

One problem with this token bridge is that it mints tokens (such as USDCet) that sometimes don't have a lot of liquidity or have liquidity only on one specific protocol. The goal of this project is to have users not have to deal with this and swap them automatically for natively used tokens to improve their experience using the bridge.

## Outbox & Inbox

We built two contracts that wrap the Portal token bridge: Outbox and Inbox.

The Outbox can be used to initiate a new token bridge, optionally swapping the token for the bridge token. For example, if a user has DAI the Outbox can swap the DAI for USDCet and then send that one through the bridge since native DAI is unlikely to have liquidity on the destination chain.

The Inbox is the one that receives the messages. It receives the bridge token and optionally swaps it for a natively used one. For example, if it receives USDCet it can swap it for USDT and send that to the user so that they don't have to deal with swapping USDCet themselves.

# This is a Hardhat project

Some tasks that can be run:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
