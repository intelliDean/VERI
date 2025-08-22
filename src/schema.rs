// @generated automatically by Diesel CLI.

diesel::table! {
    contracts_created (id) {
        id -> Int4,
        contract_address -> Varchar,
        owner -> Varchar,
        timestamp -> Nullable<Timestamp>,
    }
}

diesel::table! {
    manufacturers_info (id) {
        id -> Int4,
        manufacturer_address -> Text,
        manufacturer_name -> Text,
        timestamp -> Nullable<Timestamp>,
        tnx_hash -> Text,
    }
}

diesel::allow_tables_to_appear_in_same_query!(
    contracts_created,
    manufacturers_info,
);
