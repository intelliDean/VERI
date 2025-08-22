// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("OwnershipModule", (m) => {


  const ownership = m.contract("Ownership", ["0xF2E7E2f51D7C9eEa9B0313C2eCa12f8e43bd1855"]);
  return { ownership };
});
