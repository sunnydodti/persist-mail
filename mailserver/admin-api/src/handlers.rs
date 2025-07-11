use actix_web::{web, HttpRequest};
use serde::Serialize;
use std::process::Command;
use log::{info, error};

#[derive(Serialize)]
pub struct Response {
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
}

fn run_docker_command(args: &[&str]) -> Result<String, String> {
    let output = Command::new("docker")
        .args(args)
        .output()
        .map_err(|e| format!("Failed to execute docker command: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();

    if output.status.success() {
        Ok(stdout)
    } else {
        Err(if stderr.is_empty() { stdout } else { stderr })
    }
}

pub async fn create_mailbox(
    username: web::Path<String>,
    req: HttpRequest,
    api_key: web::Data<String>,
) -> Result<web::Json<Response>, crate::error::ApiError> {
    let received_key = req.headers()
        .get("X-API-Key")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");

    // Log exact values for debugging (masking part of the keys)
    let received_masked = if received_key.len() > 4 {
        format!("{}***{}", &received_key[..2], &received_key[received_key.len()-2..])
    } else {
        "invalid".to_string()
    };
    let expected_masked = format!("{}***{}", &api_key[..2], &api_key[api_key.len()-2..]);
    info!("API key comparison - Expected: {}, Received: {}", expected_masked, received_masked);
    
    if received_key != api_key.as_str() {
        error!("Invalid API key attempt");
        return Err(crate::error::ApiError::AuthenticationError);
    }

    // Validate username
    if username.contains(|c: char| !c.is_ascii_alphanumeric() && c != '.' && c != '-' && c != '_') {
        error!("Invalid username format: {}", username);
        return Err(crate::error::ApiError::InvalidUsername);
    }

    info!("Creating mailbox for user: {}", username);

    // Check if mailserver is running
    match run_docker_command(&["ps", "--filter", "name=mailserver", "--format", "{{.Names}}"]) {
        Ok(output) => {
            if !output.contains("mailserver") {
                error!("mailserver container not running");
                return Err(crate::error::ApiError::CommandError(
                    "mailserver container not running".to_string()
                ));
            }
        }
        Err(e) => {
            error!("Docker check failed: {}", e);
            return Err(crate::error::ApiError::CommandError(e));
        }
    }

    // Check if setup.sh exists and is executable
    match run_docker_command(&["exec", "mailserver", "test", "-x", "/usr/local/bin/setup.sh"]) {
        Ok(_) => info!("setup.sh is executable"),
        Err(e) => {
            error!("setup.sh check failed: {}", e);
            return Err(crate::error::ApiError::CommandError(
                "setup.sh not found or not executable".to_string()
            ));
        }
    }

    // Try to create the mailbox
    info!("Running setup.sh for {}", username);
    match run_docker_command(&[
        "exec",
        "mailserver",
        "/usr/local/bin/setup.sh",
        "email",
        "add",
        &username,
        "password123",
    ]) {
        Ok(output) => {
            info!("Command output: {}", output);
            Ok(web::Json(Response {
                status: "success".to_string(),
                error: None,
                message: Some(format!("Mailbox {} created successfully", username)),
            }))
        }
        Err(e) => {
            error!("Command failed: {}", e);
            Err(crate::error::ApiError::CommandError(e))
        }
    }
}

pub async fn health_check() -> Result<web::Json<Response>, crate::error::ApiError> {
    info!("Health check requested");

    // Check Docker and mailserver status
    match run_docker_command(&["ps", "--filter", "name=mailserver"]) {
        Ok(output) => {
            if !output.contains("mailserver") {
                return Ok(web::Json(Response {
                    status: "warning".to_string(),
                    error: Some("mailserver not running".to_string()),
                    message: None,
                }));
            }
        }
        Err(e) => {
            error!("Docker check failed: {}", e);
            return Ok(web::Json(Response {
                status: "warning".to_string(),
                error: Some(format!("docker error: {}", e)),
                message: None,
            }));
        }
    }

    Ok(web::Json(Response {
        status: "healthy".to_string(),
        error: None,
        message: None,
    }))
}
