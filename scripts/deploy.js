
const zeroAddress = "0x0000000000000000000000000000000000000000"
const args =
[
   "_name",
   "_symbol",
    1,
  [] ,
  zeroAddress ,
  1000000000
]
async function main() {
  const token = await hre.ethers.deployContract("ReferenceToken",args);
  await token.waitForDeployment();

  console.log(
    `token deployed to ${token.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
