// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const InsuranceClaim = await ethers.getContractFactory("InsuranceClaim");
  const insurance = await InsuranceClaim.deploy(); // Fix the deployment variable
  await insurance.deployed();

  console.log("InsuranceClaim contract deployed to:", insurance.address); // Fix the variable reference
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
