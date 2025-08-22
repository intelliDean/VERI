use crate::config::app_router::{Authenticity, AuthenticityEvents};
use crate::config::app_router::{ContractCreatedFilter, ManufacturerRegisteredFilter};
use diesel::{PgConnection, RunQueryDsl};
use std::sync::Arc;

use crate::config::app_state::AppState;
use crate::models::auth::{NewContractCreated, NewManufacturer};
use crate::schema::{contracts_created, manufacturers_info};
use chrono::Utc;
use diesel::prelude::*;
use diesel::prelude::*;
use ecdsa::SigningKey;
use ethers::core::k256::Secp256k1;
use ethers::core::utils::to_checksum;
use ethers::prelude::*;
use ethers::prelude::*;
use eyre::Result;

pub async fn listen_for_events(state: &Arc<AppState>) -> Result<()> {
    let contract = state.contract.clone();
    let client = contract.client();

    // Fetch historical events from the last 1,000 blocks in chunks
    let latest_block = client.get_block_number().await.map_err(|e| {
        eprintln!("Failed to get latest block: {:?}", e);
        eyre::eyre!("Failed to get latest block: {}", e)
    })?;
    let from_block = latest_block.saturating_sub(U64::from(1000));
    let chunk_size = 499;

    // Process historical events in chunks
    let mut current_block = from_block;
    while current_block < latest_block {
        let to_block = (current_block + chunk_size).min(latest_block);
        eprintln!(
            "Querying historical events from block {} to {} (range: {})",
            current_block,
            to_block,
            to_block - current_block + 1
        );

        // Event filters for the chunk
        let manufacturer_registered_filter = contract
            .event::<ManufacturerRegisteredFilter>()
            .from_block(current_block)
            .to_block(to_block);

        let contract_created_filter = contract
            .event::<ContractCreatedFilter>()
            .from_block(current_block)
            .to_block(to_block);

        // Fetch historical events with metadata
        let manufacturer_registered_logs = manufacturer_registered_filter
            .query_with_meta()
            .await
            .map_err(|e| {
            eprintln!(
                "Failed to query ManufacturerRegistered events for blocks {} to {}: {:?}",
                current_block, to_block, e
            );
            eyre::eyre!("Failed to query ManufacturerRegistered events: {}", e)
        })?;

        let contract_created_logs =
            contract_created_filter
                .query_with_meta()
                .await
                .map_err(|e| {
                    eprintln!(
                        "Failed to query ContractCreated events for blocks {} to {}: {:?}",
                        current_block, to_block, e
                    );
                    eyre::eyre!("Failed to query ContractCreated events: {}", e)
                })?;

        // Process historical events
        // let mut db_pool = state.db_pool.lock().await;
        let conn = &mut state.db_pool.get().map_err(|e| {
            eprintln!("Failed to get DB connection: {:?}", e);
            eyre::eyre!("Failed to get DB connection: {}", e)
        })?;
        for (event, meta) in manufacturer_registered_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_manufacturer_registered_event(&event, conn, txn_hash, &contract).await?;
        }
        for (event, meta) in contract_created_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_contract_created_event(&event, conn, txn_hash)?;
        }

        current_block = to_block + 1;
    }

    // Stream future events
    eprintln!("Starting event stream from block {}", latest_block + 1);
    let events = contract.events().from_block(latest_block + 1);
    let mut stream = events.stream_with_meta().await.map_err(|e| {
        eprintln!("Failed to create event stream: {:?}", e);
        eyre::eyre!("Failed to create event stream: {}", e)
    })?;

    loop {
        match stream.next().await {
            Some(Ok((AuthenticityEvents::ManufacturerRegisteredFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                // let mut db_pool = state.db_pool.lock().await;
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_manufacturer_registered_event(&event, conn, txn_hash, &contract).await?;
            }
            Some(Ok((AuthenticityEvents::ContractCreatedFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                // let mut db_pool = state.db_pool.lock().await;
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_contract_created_event(&event, conn, txn_hash)?;
            }
            Some(Ok((AuthenticityEvents::Eip712DomainChangedFilter(_event), meta))) => {
                eprintln!(
                    "EIP712DomainChanged event received (tx: 0x{})",
                    hex::encode(meta.transaction_hash)
                );
                continue;
            }
            Some(Err(e)) => {
                eprintln!("Event stream error: {:?}", e);
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                continue;
            }
            None => {
                eprintln!("Event stream ended unexpectedly");
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                continue;
            }
        }
    }
}

async fn process_manufacturer_registered_event(
    event: &ManufacturerRegisteredFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
    contract: &Authenticity<SignerMiddleware<Provider<Http>, Wallet<SigningKey<Secp256k1>>>>,
) -> Result<()> {
    let manufacturer_address = to_checksum(&event.manufacturer_address, None);

    // Check if manufacturer exists
    if manufacturers_info::table //this will return a boolean
        .filter(manufacturers_info::manufacturer_address.eq(&manufacturer_address))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!(
                "Failed to check existing manufacturer {}: {:?}",
                manufacturer_address, e
            );
            eyre::eyre!("Failed to check existing manufacturer: {}", e)
        })?
    {
        eprintln!(
            "Skipping duplicate manufacturer registration for {} (tx: {:?})",
            manufacturer_address, txn_hash
        );
        return Ok(());
    }

    // Fetch the actual manufacturer name from the contract
    let manufacturer = contract
        .get_manufacturer(event.manufacturer_address)
        .call()
        .await
        .map_err(|e| {
            eprintln!(
                "Failed to call getManufacturer for address {}: {:?}",
                manufacturer_address, e
            );
            eyre::eyre!("Failed to call getManufacturer: {}", e)
        })?;

    let manufacturer_name = manufacturer.name;

    // Insert the manufacturer
    diesel::insert_into(manufacturers_info::table)
        .values(NewManufacturer {
            manufacturer_address,
            manufacturer_name,
            tnx_hash: txn_hash.unwrap(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert manufacturer: {:?}", e);
            eyre::eyre!("Failed to insert manufacturer: {}", e)
        })?;

    Ok(())
}
fn process_contract_created_event(
    event: &ContractCreatedFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let contract_address = to_checksum(&event.contract_address, None);
    let owner = to_checksum(&event.owner, None);

    // Check if contract created exists
    let exists: bool = contracts_created::table
        .filter(contracts_created::contract_address.eq(&contract_address))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!(
                "Failed to check existing contract {}: {:?}",
                contract_address, e
            );
            eyre::eyre!("Failed to check existing contract: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate contract created for {} (tx: {:?})",
            contract_address, txn_hash
        );
        return Ok(());
    }

    // Insert the contract created
    diesel::insert_into(contracts_created::table)
        .values(NewContractCreated {
            contract_address,
            owner,
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert contract created: {:?}", e);
            eyre::eyre!("Failed to insert contract created: {}", e)
        })?;

    Ok(())
}
