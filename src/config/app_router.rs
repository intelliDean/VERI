use crate::authenticity::get_manufacturer::get_manufacturer;
use crate::authenticity::is_username_exist::manufacturer_name_exists;
use crate::config::app_state::AppState;
use crate::config::swagger_config::ApiDoc;
use crate::ownership::get_my_items::{ get_owner_items};
use crate::ownership::get_user_info::get_user;
use crate::ownership::is_name_exist::user_exists;
use crate::services::create_eip712::create_certificate;
use crate::services::other_tests::{
    generate_signature, get_owner, manufacturer_registers,
    verify_signature,
};
use crate::services::qr_code::generate_qr_code;
use crate::services::verify_authenticity::verify_authenticity;
use axum::routing::{get, post};
use axum::Router;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use actix_web::web::route;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use crate::ownership::get_transfer_code::get_ownership_code;
use crate::ownership::transfer_ownership_code::transfer_ownership_code;

pub fn paths(state: Arc<AppState>, path: RouterPath) -> Router {
    let app = Router::new()
        .route(&path.generate_signature, post(generate_signature))
        .route(&path.verify_authenticity, post(verify_authenticity))
        .route(&path.sign_up, post(manufacturer_registers))
        .route(&path.get_owner, get(get_owner))
        .route(&path.verify_signature, post(verify_signature))
        .route(&path.create_certificate, post(create_certificate))
        .route(&path.transfer_ownership, get(transfer_ownership_code))
        .route(&path.qr_code, post(generate_qr_code))
        .route(&path.get_manufacturer, get(get_manufacturer))
        .route(&path.transfer_code, get(get_ownership_code))
        .route(&path.is_user_exist, get(user_exists))
        .route(&path.get_my_items, get(get_owner_items))
        .route(&path.manufacturer_name_exists, get(manufacturer_name_exists))
        .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", ApiDoc::openapi()))
        .with_state(state)
        .layer(CorsLayer::permissive()); // Optional: Enable CORS

    app
}


#[derive(Clone, Serialize, Deserialize, Debug)]
pub struct RouterPath {
    pub  generate_signature: String,
    pub verify_authenticity: String,
    pub sign_up: String,
    pub get_owner: String,
    pub verify_signature: String,
    pub create_certificate: String,
    pub qr_code: String,
    pub get_manufacturer: String,
    pub manufacturer_name_exists: String,
    pub get_user: String,
    pub is_user_exist: String,
    pub get_my_items: String,
    pub transfer_ownership: String,
    pub transfer_code: String,
}

impl RouterPath {
    pub fn init() -> Self {
        Self {
            generate_signature: "/generate_signature".to_string(),
            verify_authenticity: "/verify_authenticity".to_string(),
            sign_up: "/manufacturer_registers".to_string(),
            get_owner: "/get_owner/{address}".to_string(),
            verify_signature: "/verify_signature".to_string(),
            create_certificate: "/create_certificate".to_string(),
            qr_code: "/qr_code".to_string(),
            get_manufacturer: "/api/manufacturer".to_string(),
            manufacturer_name_exists: "/api/manufacturer/exists".to_string(),
            get_user: "/api/user/get".to_string(),
            is_user_exist: "/api/user/exists".to_string(),
            get_my_items: "/api/items/owner".to_string(),
            transfer_ownership: "/api/transfer_ownership".to_string(),
            transfer_code: "/api/get_transfer_code".to_string(),
        }
    }
}