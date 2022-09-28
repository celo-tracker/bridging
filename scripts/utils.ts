export async function sendTx(tx: Promise<any>) {
  const receipt = await tx;
  console.log(`Send tx with hash ${receipt.transactionHash}`);
}
