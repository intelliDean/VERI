use axum::Router;
use std::net::SocketAddr;
use std::sync::Arc;
use crate::config::app_router::paths;
use crate::config::app_state::AppState;
use crate::models::router_path::RouterPath;
use anyhow::Result;
use dotenv::dotenv;
use tokio::net::TcpListener;
use crate::events::authenticity_event_listener::listen_for_events;

pub async fn server() -> Result<()> {
    eprintln!("PROJECT STARTING...");
    // Load environment variables
    dotenv().ok();
    // dotenv::from_path("../.env").ok();

    // let state = AppState::init_app_state().await.unwrap();

    let arc_state = Arc::from(AppState::init_app_state().await.unwrap());

    let state_clone = arc_state.clone();
    tokio::spawn(async move {
        if let Err(e) = listen_for_events(&state_clone).await {
            eprintln!("Error in event listener: {:?}", e);
        }
    });

    // Define routes
    let app: Router = paths(arc_state, RouterPath::init());

    // Start the server
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    let listener = TcpListener::bind(addr).await?;

    eprintln!("Server running on {:?}", addr);
    eprintln!("Swagger UI available at {:?}/swagger-ui/index.html#/", addr);

    axum::serve(listener, app).await?;

    Ok(()) // another way to say return nothing
}
