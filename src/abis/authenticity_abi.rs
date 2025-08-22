use ethers::contract::abigen;

//abi path
abigen!(
    Authenticity,
    "./hh-artifacts/contracts/Authenticity.sol/Authenticity.json",
    event_derives(serde::Deserialize, serde::Serialize)
);