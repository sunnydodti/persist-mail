use actix_web::{web, HttpRequest};
use serde::Serialize;
use std::process::Command;
use log::{info, error};
use crate::error::ApiError;

#[derive(Serialize)]
pub struct Response {
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
}

pub async fn create_mailbox(
    username: web::Path<String>,
    req: HttpRequest,
    api_key: web::Data<String>,
) -> Result<web::Json<Response>, ApiError> {
    // Validate API key
    if req.headers()
        .get("X-API-Key")
        .map_or("", |h| h.to_str().unwrap_or("")) != api_key.as_str()
    {
        error!("Invalid API key attempt");
        return Err(ApiError::AuthenticationError);
    }

    // Validate username
    if username.contains(|c: char| !c.is_ascii_alphanumeric() && c != '.' && c != '-' && c != '_') {
        error!("Invalid username format: {}", username);
        return Err(ApiError::InvalidUsername);
    }

    info!("Creating mailbox for user: {}", username);

    // Execute mailbox creation command
    let output = Command::new("docker")
        .args(&[
            "exec",
            "mailserver",
            "/usr/local/bin/setup.sh",
            "email",
            "add",
            &username,
            "password123",
        ])
        .output()
        .map_err(|e| {
            error!("Failed to execute command: {}", e);
            ApiError::Internal(e.to_string())
        })?;

    if output.status.success() {
        info!("Successfully created mailbox: {}", username);
        Ok(web::Json(Response {
            status: "success".to_string(),
            error: None,
            message: Some(format!("Mailbox {} created successfully", username)),
        }))
    } else {
        let error_msg = String::from_utf8_lossy(&output.stderr);
        error!("Failed to create mailbox: {}", error_msg);
        Err(ApiError::CommandError(error_msg.to_string()))
    }
}
