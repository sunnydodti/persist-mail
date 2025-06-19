use actix_web::{HttpResponse, ResponseError};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("Authentication failed")]
    AuthenticationError,
    
    #[error("Invalid username format")]
    InvalidUsername,
    
    #[error("Command execution failed: {0}")]
    CommandError(String),
    
    #[error("Internal server error: {0}")]
    Internal(String),
}

impl ResponseError for ApiError {
    fn error_response(&self) -> HttpResponse {
        match self {
            ApiError::AuthenticationError => {
                HttpResponse::Forbidden().json(json!({
                    "status": "error",
                    "error": "forbidden"
                }))
            }
            ApiError::InvalidUsername => {
                HttpResponse::BadRequest().json(json!({
                    "status": "error",
                    "error": "invalid username format"
                }))
            }
            ApiError::CommandError(msg) => {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "error": "command failed",
                    "message": msg
                }))
            }
            ApiError::Internal(msg) => {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "error": "internal error",
                    "message": msg
                }))
            }
        }
    }
}
