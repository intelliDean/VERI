// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("AuthenticityModule", (m) => {


    const authenticity = m.contract("Authenticity", ["ownership address"]);
    return { authenticity };
});
