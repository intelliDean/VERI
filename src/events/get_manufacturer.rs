use std::sync::Arc;
use crate::events::contract_models::Manufacturer;
use crate::schema::manufacturers;
use diesel::{PgConnection, RunQueryDsl};
use diesel::prelude::*;
use eyre::Result;
use crate::config::app_state::AppState;

// pub fn get_manufacturer(
//    state: Arc<AppState>,
//     address: &str,
// ) -> Result<Manufacturer> {
//     let conn = &mut state.db_pool.get().map_err(|e| {
//         eprintln!("Failed to get DB connection: {:?}", e);
//         eyre::eyre!("Failed to get DB connection: {}", e)
//     })?;


    // manufacturers::table
    //     .filter(manufacturers::manufacturer_address.eq(address))
    //     .first::<Manufacturer>(conn)
    //     .map_err(|e| {
    //         eprintln!("Failed to fetch manufacturer with address {}: {:?}", address, e);
    //         eyre::eyre!("Failed to fetch manufacturer: {}", e)
    //     })
// }