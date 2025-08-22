const hre = require("hardhat");
require("dotenv").config();


const {OWNER, CERTIFICATE, SIGNING_DOMAIN, SIGNATURE_VERSION} = process.env;

async function main() {


    console.log("🚀 Deploying contracts...OwnershipLib");
    // Step 1: Deploy OwnershipLib
    const ownershipLibFactory = await hre.ethers.getContractFactory("OwnershipLib");
    const ownershipLib = await ownershipLibFactory.deploy();
    console.log(`📚 OwnershipLib deployed at: ${ownershipLib.target}`);

    console.log("🚀 Deploying contracts...Ownership Contract");


    // Step 2: Deploy Ownership using OwnershipLib
    const ownershipContract = await hre.ethers.getContractFactory("Ownership", {
        libraries: {
            // OwnershipLib: ownershipLib.target,
            OwnershipLib: ownershipLib.target,
        },
    });
    const ownership = await ownershipContract.deploy(OWNER);
    console.log(`📦 Ownership deployed at: ${ownership.target}`);

    console.log("🚀 Deploying contracts...Authenticity");
    // Step 3: Deploy Authenticity with Ownership address
    const AuthenticityFactory = await hre.ethers.getContractFactory("Authenticity");

    const authenticity = await AuthenticityFactory.deploy(
        ownership.target,
        CERTIFICATE,
        SIGNING_DOMAIN,
        SIGNATURE_VERSION
    );
    console.log(`🧾 Authenticity deployed at: ${authenticity.target}`);

    console.log("✅ Deployment complete.");
}

main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
});
//BASE
// 📚 OwnershipLib deployed at: 0x9c7bd4cbfF0D54e0f42FE1e63A11BEaf6665D733
// https://sepolia.basescan.org/address/0x9c7bd4cbfF0D54e0f42FE1e63A11BEaf6665D733#code

// 📦 Ownership deployed at: 0x6df9dFdeb719A41eCE6f23CF1AaE3085dEa26A3F
// https://sepolia.basescan.org/address/0x6df9dFdeb719A41eCE6f23CF1AaE3085dEa26A3F#code

// 🧾 Authenticity deployed at: 0xF7132c4A07bC0515003D5CEC76e38ceeFA261607
// https://sepolia.basescan.org/address/0xF7132c4A07bC0515003D5CEC76e38ceeFA261607#code

// to verify a contract, you need the contract address and also the constructor parameters
// npx hardhat verify --network base 0xf36f55D6Df2f9d5C7829ed5751d7E88FD3E82c2E 0xF2E7E2f51D7C9eEa9B0313C2eCa12f8e43bd1855 0x527caBd4bb83F94f1Fc1888D0691EF95e86795A1


//AVALANCHE
// 📚 OwnershipLib deployed at: 0xF8459F087f8583f57c8Ad313c3805ECE79D127DE
// https://testnet.snowtrace.io/address/0xF8459F087f8583f57c8Ad313c3805ECE79D127DE#code

// 📦 Ownership deployed at: 0xE83BA3F5Ac6bCD62715B8Da620d014b17acA4319
// https://testnet.snowtrace.io/address/0xE83BA3F5Ac6bCD62715B8Da620d014b17acA4319#code

// 🧾 Authenticity deployed at: 0x63616b20f7A12f9Ba67BDF957f1400CDbF725fF8
// https://testnet.snowtrace.io/address/0x63616b20f7A12f9Ba67BDF957f1400CDbF725fF8#code

//VERY MAINNET
// 📚 OwnershipLib deployed at: 0x442576ef8EA93B6aA30cb7C779b8cC1e402bca5e

// 📦 Ownership deployed at: 0xBbcD22fd30EFA3c859f3C30a7224aB257D20b112

// 🧾 Authenticity deployed at: 0x97D9bcE273974455Bfc3A51E8Fd956D4209066A3