use ethers::contract::abigen;

abigen!(
    Ownership,
    "./hh-artifacts/contracts/Ownership.sol/Ownership.json",
    event_derives(serde::Deserialize, serde::Serialize)
);