use config::server::server;

mod config;
mod models;
mod services;
mod utility;
mod schema;
mod events;

#[tokio::main]
async fn main() {
    server().await.expect("Error!");
}
