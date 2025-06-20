from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # API Settings
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "PersistMail API"
    
    # CORS Settings
    CORS_ORIGINS_STR: str = "*"  # In production, replace with comma-separated domains
    
    @property
    def CORS_ORIGINS(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS_STR.split(",")]
    
    # Database Settings
    DATABASE_URL: str = "sqlite:///./persistmail.db"    # Mail Server Settings
    MAIL_DOMAIN: str = ""         # e.g., example.com
    IMAP_HOST: str = ""          # e.g., imap.example.com
    IMAP_PORT: int = 993
    SMTP_HOST: str = ""          # e.g., smtp.example.com
    SMTP_PORT: int = 465
    ADMIN_EMAIL: str = ""        # Admin email for creating mailboxes
    ADMIN_PASSWORD: str = ""     # Admin password
    IMAP_SECRET: str = ""        # Common password for all mailboxes
    IS_PREMIUM_DOMAIN: bool = False
    
    # Email Settings
    DEFAULT_HOURS_RETENTION: int = 24
    DEFAULT_EMAIL_LIMIT: int = 25
    MAX_EMAIL_LIMIT: int = 50
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
