use crate::config::app_router::paths;
use crate::config::app_state::AppState;
use crate::events::authenticity_event_listener::listen_for_authenticity_events;
use crate::events::ownership_event_listener::listen_for_ownership_events;
use crate::models::router_path::RouterPath;
use anyhow::Result;
use axum::Router;
use dotenv::dotenv;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::net::TcpListener;

pub async fn server() -> Result<()> {
    eprintln!("PROJECT STARTING...");
    // Load environment variables
    dotenv().ok();
    // dotenv::from_path("../.env").ok();

    // let state = AppState::init_app_state().await.unwrap();

    let arc_state = Arc::from(AppState::init_app_state().await.unwrap());

    let state_clone1 = arc_state.clone();
    let state_clone2 = arc_state.clone();

    tokio::spawn(async move {
        loop {
            if let Err(e) = listen_for_authenticity_events(&state_clone1).await {
                eprintln!("Error in authenticity listener, retrying in 5s: {:?}", e);
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
            }
        }
    });

    tokio::spawn(async move {
        if let Err(e) = listen_for_ownership_events(&state_clone2).await {
            eprintln!("Error in event listener for ownership: {:?}", e);
            tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
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
