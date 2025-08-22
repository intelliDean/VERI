use crate::abis::ownership_abi::{
    AuthenticitySetFilter, CodeRevokedFilter, ItemCreatedFilter, OwnershipClaimedFilter,
    OwnershipCodeFilter, OwnershipCreatedFilter, UserRegisteredFilter,
};
use crate::abis::ownership_abi::{Ownership, OwnershipEvents};
use crate::config::app_state::AppState;
use crate::events::contract_models::{
    NewAuthenticitySetting, NewCodeRevokation, NewContract, NewItem, NewOwnershipClaim
    , NewUserInfo,
};
use crate::schema::{
    authenticity_settings, code_revokations, contracts, items, ownership_claims,
    users_info,
};
use chrono::Utc;
use diesel::prelude::*;
use diesel::{PgConnection, RunQueryDsl};
use ecdsa::SigningKey;
use ethers::core::k256::Secp256k1;
use ethers::core::utils::to_checksum;
use ethers::prelude::*;
use eyre::Result;
use std::sync::Arc;

pub async fn listen_for_ownership_events(state: &Arc<AppState>) -> Result<()> {
    let contract = state.ownership_contract.clone();
    let client = contract.client();

    // Fetch historical events from the last 1,000 blocks in chunks
    let latest_block = client.get_block_number().await.map_err(|e| {
        eprintln!("Failed to get latest block: {:?}", e.to_string());
        eyre::eyre!("Failed to get latest block: {}", e)
    })?;
    let from_block = latest_block.saturating_sub(U64::from(1000));
    let chunk_size = U64::from(499);

    // Process historical events in chunks
    let mut current_block = from_block;
    while current_block < latest_block {
        let to_block = (current_block + chunk_size).min(latest_block);
        eprintln!(
            "Querying Ownership historical events from block {} to {} (range: {})",
            current_block,
            to_block,
            to_block - current_block + 1
        );

        // Event filters for the chunk
        let ownership_created_filter = contract
            .event::<OwnershipCreatedFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let user_registered_filter = contract
            .event::<UserRegisteredFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let ownership_code_filter = contract
            .event::<OwnershipCodeFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let item_created_filter = contract
            .event::<ItemCreatedFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let ownership_claimed_filter = contract
            .event::<OwnershipClaimedFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let code_revoked_filter = contract
            .event::<CodeRevokedFilter>()
            .from_block(current_block)
            .to_block(to_block);
        let authenticity_set_filter = contract
            .event::<AuthenticitySetFilter>()
            .from_block(current_block)
            .to_block(to_block);

        // Fetch historical events with metadata
        let ownership_created_logs = ownership_created_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query OwnershipCreated events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query OwnershipCreated events: {}", e)
        })?;
        let user_registered_logs = user_registered_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query UserRegistered events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query UserRegistered events: {}", e)
        })?;
        let ownership_code_logs = ownership_code_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query OwnershipCode events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query OwnershipCode events: {}", e)
        })?;
        let item_created_logs = item_created_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query ItemCreated events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query ItemCreated events: {}", e)
        })?;
        let ownership_claimed_logs = ownership_claimed_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query OwnershipClaimed events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query OwnershipClaimed events: {}", e)
        })?;
        let code_revoked_logs = code_revoked_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query CodeRevoked events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query CodeRevoked events: {}", e)
        })?;
        let authenticity_set_logs = authenticity_set_filter.query_with_meta().await.map_err(|e| {
            eprintln!(
                "Failed to query AuthenticitySet events for blocks {} to {}: {:?}",
                current_block, to_block, e.to_string()
            );
            eyre::eyre!("Failed to query AuthenticitySet events: {}", e)
        })?;

        // Process historical events
        let conn = &mut state.db_pool.get().map_err(|e| {
            eprintln!("Failed to get DB connection: {:?}", e);
            eyre::eyre!("Failed to get DB connection: {}", e)
        })?;
        for (event, meta) in ownership_created_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_ownership_created_event(&event, conn, txn_hash)?;
        }
        for (event, meta) in user_registered_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_user_registered_event(&event, conn, txn_hash)?;
        }
        for (event, meta) in ownership_code_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            // process_ownership_code_event(&event, conn, txn_hash, &contract).await?;
        }
        for (event, meta) in item_created_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_item_created_event(&event, conn, txn_hash, &contract).await?;
        }
        for (event, meta) in ownership_claimed_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_ownership_claimed_event(&event, conn, txn_hash)?;
        }
        for (event, meta) in code_revoked_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_code_revoked_event(&event, conn, txn_hash)?;
        }
        for (event, meta) in authenticity_set_logs {
            let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
            process_authenticity_set_event(&event, conn, txn_hash)?;
        }

        current_block = to_block + 1;
    }

    // Stream future events
    eprintln!("Starting Ownership event stream from block {}", latest_block + 1);
    let events = contract.events().from_block(latest_block + 1);
    let mut stream = events.stream_with_meta().await.map_err(|e| {
        eprintln!("Failed to create event stream: {:?}", e.to_string());
        eyre::eyre!("Failed to create event stream: {}", e)
    })?;

    loop {
        match stream.next().await {
            Some(Ok((OwnershipEvents::OwnershipCreatedFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_ownership_created_event(&event, conn, txn_hash)?;
            }
            Some(Ok((OwnershipEvents::UserRegisteredFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_user_registered_event(&event, conn, txn_hash)?;
            }
            Some(Ok((OwnershipEvents::OwnershipCodeFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                // process_ownership_code_event(&event, conn, txn_hash, &contract).await?;
            }
            Some(Ok((OwnershipEvents::ItemCreatedFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_item_created_event(&event, conn, txn_hash, &contract).await?;
            }
            Some(Ok((OwnershipEvents::OwnershipClaimedFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_ownership_claimed_event(&event, conn, txn_hash)?;
            }
            Some(Ok((OwnershipEvents::CodeRevokedFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_code_revoked_event(&event, conn, txn_hash)?;
            }
            Some(Ok((OwnershipEvents::AuthenticitySetFilter(event), meta))) => {
                let txn_hash = Some(format!("0x{}", hex::encode(meta.transaction_hash)));
                let conn = &mut state.db_pool.get().map_err(|e| {
                    eprintln!("Failed to get DB connection: {:?}", e);
                    eyre::eyre!("Failed to get DB connection: {}", e)
                })?;
                process_authenticity_set_event(&event, conn, txn_hash)?;
            }
            Some(Err(e)) => {
                eprintln!("Event stream error: {:?}", e.to_string());
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

fn process_ownership_created_event(
    event: &OwnershipCreatedFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let contract_address = to_checksum(&event.contract_address, None);
    let owner = to_checksum(&event.owner, None);

    // Check if contract exists
    let exists: bool = contracts::table
        .filter(contracts::contract_address.eq(&contract_address))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!("Failed to check existing contract {}: {:?}", contract_address, e);
            eyre::eyre!("Failed to check existing contract: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate contract created for {} (tx: {:?})",
            contract_address, txn_hash
        );
        return Ok(());
    }

    // Insert the contract
    diesel::insert_into(contracts::table)
        .values(NewContract {
            contract_address,
            owner,
            tnx_hash: txn_hash.unwrap(),
            created_at: Utc::now().naive_utc(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert contract: {:?}", e);
            eyre::eyre!("Failed to insert contract: {}", e)
        })?;

    Ok(())
}

fn process_user_registered_event(
    event: &UserRegisteredFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let user_address = to_checksum(&event.user_address, None);
    let username = event.username.clone();

    // Check if user exists
    let exists: bool = users_info::table
        .filter(users_info::user_address.eq(&user_address))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!("Failed to check existing user {}: {:?}", user_address, e);
            eyre::eyre!("Failed to check existing user: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate user registration for {} (tx: {:?})",
            user_address, txn_hash
        );
        return Ok(());
    }

    // Insert the user
    diesel::insert_into(users_info::table)
        .values(NewUserInfo {
            user_address,
            username: username.to_string(),
            is_registered: true,
            created_at: Utc::now().naive_utc(),
            tnx_hash: txn_hash.unwrap(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert user: {:?}", e);
            eyre::eyre!("Failed to insert user: {}", e)
        })?;

    Ok(())
}

// async fn process_ownership_code_event(
//     event: &OwnershipCodeFilter,
//     conn: &mut PgConnection,
//     txn_hash: Option<String>,
//     contract: &Ownership<SignerMiddleware<Provider<Http>, Wallet<SigningKey<Secp256k1>>>>,
// ) -> Result<()> {
//     let item_id = format!("0x{}", hex::encode(event.item_id));
//     let temp_owner = to_checksum(&event.temp_owner, None);
//
//     // Fetch item details to get item_owner
//     let item = contract
//         .get_item(event.item_id)
//         .call()
//         .await
//         .map_err(|e| {
//             eprintln!("Failed to call get_item for hash {}: {:?}", item_id, e.to_string());
//             eyre::eyre!("Failed to call get_item: {}", e)
//         })?;
//     let item_owner = to_checksum(&item.owner, None);
//
//     // Check if ownership code exists
//     let exists: bool = ownership_codes::table
//         .filter(ownership_codes::ownership_code.eq(&ownership_code))
//         .select(diesel::dsl::count_star())
//         .first::<i64>(conn)
//         .map(|count| count > 0)
//         .map_err(|e| {
//             eprintln!("Failed to check existing ownership code {}: {:?}", item_id, e);
//             eyre::eyre!("Failed to check existing ownership code: {}", e)
//         })?;
//
//     if exists {
//         eprintln!(
//             "Skipping duplicate ownership code {} (tx: {:?})",
//             item_id, txn_hash
//         );
//         return Ok(());
//     }
//
//     let ownership_code = format!("0x{}", hex::encode(event.ownership_code));
//
//     // Insert the ownership code
//     diesel::insert_into(ownership_codes::table)
//         .values(NewOwnershipCode {
//             ownership_code: ownership_code.to_string(),
//             item_owner,
//             temp_owner,
//             created_at: Utc::now().naive_utc(),
//             tnx_hash: txn_hash.unwrap(),
//         })
//         .execute(conn)
//         .map_err(|e| {
//             eprintln!("Failed to insert ownership code: {:?}", e);
//             eyre::eyre!("Failed to insert ownership code: {}", e)
//         })?;
//
//     Ok(())
// }

//TODO: WILL LIKELY GIVE ISSUE BECAUSE OF THE ITEM_ID
async fn process_item_created_event(
    event: &ItemCreatedFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
    contract: &Ownership<SignerMiddleware<Provider<Http>, Wallet<SigningKey<Secp256k1>>>>,
) -> Result<()> {
    let item_id = event.item_id.clone();
    let owner = to_checksum(&event.owner, None);

    // Fetch item details from the contract
    let item = contract
        .get_item(event.item_id.clone().to_string())
        .call()
        .await
        .map_err(|e| {
            eprintln!("Failed to call get_item for item_id {}: {:?}", item_id, e.to_string());
            eyre::eyre!("Failed to call get_item: {}", e)
        })?;

    // Check if item exists
    let exists: bool = items::table
        .filter(items::item_id.eq(&item_id.to_string()))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!("Failed to check existing item {}: {:?}", item_id, e);
            eyre::eyre!("Failed to check existing item: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate item creation for {} (tx: {:?})",
            item_id, txn_hash
        );
        return Ok(());
    }

    // Insert the item
    diesel::insert_into(items::table)
        .values(NewItem {
            item_id: item_id.to_string(),
            name: item.name,
            serial: item.serial,
            date: item.date.to_string().parse::<i64>().map_err(|e| {
                eprintln!("Failed to parse item date: {:?}", e);
                eyre::eyre!("Failed to parse item date: {}", e)
            })?,
            owner,
            manufacturer: item.manufacturer,
            metadata: item.metadata,
            created_at: Utc::now().naive_utc(),
            tnx_hash: txn_hash.unwrap(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert item: {:?}", e);
            eyre::eyre!("Failed to insert item: {}", e)
        })?;

    Ok(())
}

//TODO: WILL NEED TO LOOK FOR HOW TO GET THE ITEM ID
fn process_ownership_claimed_event(
    event: &OwnershipClaimedFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let new_owner = to_checksum(&event.new_owner, None);
    let old_owner = to_checksum(&event.old_owner, None);

    // Since item_id is not in the event, we need to derive it from the transaction or contract state
    // For simplicity, we'll assume item_id is fetched separately or stored in a previous event
    // Here, we'll insert without item_id and update later if needed
    diesel::insert_into(ownership_claims::table)
        .values(NewOwnershipClaim {
            item_id: String::new(), // Placeholder; ideally, fetch from contract
            new_owner,
            old_owner,
            tnx_hash: txn_hash.unwrap(),
            created_at: Utc::now().naive_utc(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert ownership claim: {:?}", e);
            eyre::eyre!("Failed to insert ownership claim: {}", e)
        })?;

    Ok(())
}

fn process_code_revoked_event(
    event: &CodeRevokedFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let item_hash = format!("0x{}", hex::encode(event.item_hash));

    // Check if revocation exists
    let exists: bool = code_revokations::table
        .filter(code_revokations::item_hash.eq(&item_hash))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!("Failed to check existing code revocation {}: {:?}", item_hash, e);
            eyre::eyre!("Failed to check existing code revocation: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate code revocation for {} (tx: {:?})",
            item_hash, txn_hash
        );
        return Ok(());
    }

    // Insert the revocation
    diesel::insert_into(code_revokations::table)
        .values(NewCodeRevokation {
            item_hash,
            tnx_hash: txn_hash.unwrap(),
            created_at: Utc::now().naive_utc(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert code revocation: {:?}", e);
            eyre::eyre!("Failed to insert code revocation: {}", e)
        })?;

    Ok(())
}

fn process_authenticity_set_event(
    event: &AuthenticitySetFilter,
    conn: &mut PgConnection,
    txn_hash: Option<String>,
) -> Result<()> {
    let authenticity_address = to_checksum(&event.authenticity_address, None);

    // Check if authenticity setting exists
    let exists: bool = authenticity_settings::table
        .filter(authenticity_settings::authenticity_address.eq(&authenticity_address))
        .select(diesel::dsl::count_star())
        .first::<i64>(conn)
        .map(|count| count > 0)
        .map_err(|e| {
            eprintln!(
                "Failed to check existing authenticity setting {}: {:?}",
                authenticity_address, e
            );
            eyre::eyre!("Failed to check existing authenticity setting: {}", e)
        })?;

    if exists {
        eprintln!(
            "Skipping duplicate authenticity setting for {} (tx: {:?})",
            authenticity_address, txn_hash
        );
        return Ok(());
    }

    // Insert the authenticity setting
    diesel::insert_into(authenticity_settings::table)
        .values(NewAuthenticitySetting {
            authenticity_address,
            tnx_hash: txn_hash.unwrap(),
            created_at: Utc::now().naive_utc(),
        })
        .execute(conn)
        .map_err(|e| {
            eprintln!("Failed to insert authenticity setting: {:?}", e);
            eyre::eyre!("Failed to insert authenticity setting: {}", e)
        })?;

    Ok(())
}