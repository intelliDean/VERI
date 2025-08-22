use chrono::NaiveDateTime;
use diesel::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::contracts)]
pub struct Contract {
    pub contract_address: String,
    pub owner: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::contracts)]
pub struct NewContract {
    pub contract_address: String,
    pub owner: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::users_info)]
pub struct UserInfo {
    pub user_address: String,
    pub username: String,
    pub is_registered: bool,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::users_info)]
pub struct NewUserInfo {
    pub user_address: String,
    pub username: String,
    pub is_registered: bool,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::manufacturers)]
pub struct Manufacturer {
    pub manufacturer_address: String,
    pub manufacturer_name: String,
    pub is_registered: bool,
    pub registered_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::manufacturers)]
pub struct NewManufacturer {
    pub manufacturer_address: String,
    pub manufacturer_name: String,
    pub is_registered: bool,
    pub registered_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::ownership_codes)]
pub struct OwnershipCode {
    pub ownership_code: String,
    pub item_owner: String,
    pub temp_owner: String,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::ownership_codes)]
pub struct NewOwnershipCode {
    pub ownership_code: String,
    pub item_owner: String,
    pub temp_owner: String,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::items)]
pub struct Item {
    pub id: i32,
    pub item_id: String,
    pub name: String,
    pub serial: String,
    pub date: i64,
    pub owner: String,
    pub manufacturer: String,
    pub metadata: Vec<String>,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::items)]
pub struct NewItem {
    pub item_id: String,
    pub name: String,
    pub serial: String,
    pub date: i64,
    pub owner: String,
    pub manufacturer: String,
    pub metadata: Vec<String>,
    pub created_at: NaiveDateTime,
    pub tnx_hash: String,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::ownership_claims)]
pub struct OwnershipClaim {
    pub id: i32,
    pub item_id: String,
    pub new_owner: String,
    pub old_owner: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::ownership_claims)]
pub struct NewOwnershipClaim {
    pub item_id: String,
    pub new_owner: String,
    pub old_owner: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::code_revokations)]
pub struct CodeRevokation {
    pub id: i32,
    pub item_hash: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::code_revokations)]
pub struct NewCodeRevokation {
    pub item_hash: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Queryable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::authenticity_settings)]
pub struct AuthenticitySetting {
    pub id: i32,
    pub authenticity_address: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}

#[derive(Insertable, Serialize, Deserialize)]
#[diesel(table_name = crate::schema::authenticity_settings)]
pub struct NewAuthenticitySetting {
    pub authenticity_address: String,
    pub tnx_hash: String,
    pub created_at: NaiveDateTime,
}