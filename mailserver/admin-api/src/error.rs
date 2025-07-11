use actix_web::{HttpResponse, http::StatusCode};
use serde_json::json;
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

impl actix_web::error::ResponseError for ApiError {
    fn error_response(&self) -> HttpResponse {
        let status = self.status_code();
        HttpResponse::build(status)
            .json(json!({
                "error": self.to_string()
            }))
    }

    fn status_code(&self) -> StatusCode {
        match *self {
            ApiError::AuthenticationError => StatusCode::FORBIDDEN,
            ApiError::InvalidUsername => StatusCode::BAD_REQUEST,
            ApiError::CommandError(_) | ApiError::Internal(_) => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}
