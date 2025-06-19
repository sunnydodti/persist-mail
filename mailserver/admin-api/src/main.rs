use actix_web::{web, App, HttpServer, HttpResponse, HttpRequest, middleware::Logger};
use serde::{Deserialize, Serialize};
use std::process::Command;
use log::{info, error};
use std::env;

#[derive(Serialize, Deserialize)]
struct Response {
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

async fn health_check() -> HttpResponse {
    info!("Health check requested");
    HttpResponse::Ok().json(HealthResponse {
        status: "healthy".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}

async fn create_mailbox(username: web::Path<String>, req: HttpRequest) -> HttpResponse {
    let api_key = match env::var("ADMIN_API_KEY") {
        Ok(key) => key,
        Err(_) => {
            error!("ADMIN_API_KEY environment variable not set");
            return HttpResponse::InternalServerError().json(Response {
                status: "error".to_string(),
                error: Some("server configuration error".to_string()),
                message: None,
            });
        }
    };

    if req.headers().get("X-API-Key").map_or("", |h| h.to_str().unwrap_or("")) != api_key {
        error!("Invalid API key attempt");
        return HttpResponse::Forbidden().json(Response {
            status: "error".to_string(),
            error: Some("forbidden".to_string()),
            message: None,
        });
    }

    info!("Creating mailbox for user: {}", username);

    let output = Command::new("docker")
        .args(&["exec", "mailserver", "/usr/local/bin/setup.sh", "email", "add", &username, "password123"])
        .output();

    match output {
        Ok(output) => {
            if output.status.success() {
                info!("Successfully created mailbox: {}", username);
                HttpResponse::Ok().json(Response {
                    status: "success".to_string(),
                    error: None,
                    message: Some(format!("Mailbox {} created successfully", username)),
                })
            } else {
                let error_msg = String::from_utf8_lossy(&output.stderr);
                error!("Failed to create mailbox: {}", error_msg);
                HttpResponse::InternalServerError().json(Response {
                    status: "error".to_string(),
                    error: Some("command failed".to_string()),
                    message: Some(error_msg.to_string()),
                })
            }
        }
        Err(e) => {
            error!("Failed to execute command: {}", e);
            HttpResponse::InternalServerError().json(Response {
                status: "error".to_string(),
                error: Some("internal error".to_string()),
                message: Some(e.to_string()),
            })
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = env::var("PORT").unwrap_or_else(|_| "5000".to_string());
    let bind_addr = format!("0.0.0.0:{}", port);

    info!("Starting server on {}", bind_addr);

    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .service(web::resource("/health").route(web::get().to(health_check)))
            .service(web::resource("/mailbox/{username}").route(web::post().to(create_mailbox)))
    })
    .bind(bind_addr)?
    .run()
    .await
}
