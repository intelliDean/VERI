use config::server::server;

mod config;
mod models;
mod services;
mod utility;
mod schema;
mod events;
mod authenticity;
mod ownership;
mod contract_models;

#[tokio::main]
async fn main() {
    server().await.expect("Error!");
}
