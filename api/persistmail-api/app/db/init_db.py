from sqlalchemy.orm import Session
from app.models.models import Domain
from app.db.session import get_db, engine
from app.core.config import settings
import sys
import os
from typing import Optional

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def validate_env_settings() -> Optional[str]:
    """Validate that all required environment variables are set."""
    required_settings = [
        ('MAIL_DOMAIN', settings.MAIL_DOMAIN),
        ('IMAP_HOST', settings.IMAP_HOST),
        ('IMAP_SECRET', settings.IMAP_SECRET),
    ]
    
    missing = [name for name, value in required_settings if not value]
    
    if missing:
        return f"Missing required environment variables: {', '.join(missing)}"
    return None

def create_default_domain(db: Session) -> Optional[Domain]:
    """Create default domain if it doesn't exist."""
    try:
        # Check if domain already exists
        existing_domain = db.query(Domain).filter(
            Domain.domain == settings.MAIL_DOMAIN
        ).first()
        
        if existing_domain:
            print(f"Domain {settings.MAIL_DOMAIN} already exists")
            return existing_domain

        # Store the shared secret (in production, use proper encryption)
        credentials_key = settings.IMAP_SECRET
          # Create new domain
        default_domain = Domain(
            domain=settings.MAIL_DOMAIN,
            imap_host=settings.IMAP_HOST,
            imap_port=settings.IMAP_PORT,
            credentials_key=credentials_key,
            is_premium=settings.IS_PREMIUM_DOMAIN,
            is_active=True
        )
        
        db.add(default_domain)
        db.commit()
        db.refresh(default_domain)
        print(f"Domain {settings.MAIL_DOMAIN} created successfully")
        return default_domain
        
    except Exception as e:
        db.rollback()
        print(f"Error creating default domain: {e}")
        return None

def init_db():
    """Initialize the database with default settings."""
    # Validate environment variables
    if error := validate_env_settings():
        print(f"Error: {error}")
        print("Please check your .env file and set all required variables")
        return False
        
    db = next(get_db())
    try:
        domain = create_default_domain(db)
        if domain:
            return True
        return False
            
    except Exception as e:
        print(f"Error initializing database: {e}")
        return False
        
    finally:
        db.close()

if __name__ == "__main__":
    success = init_db()
    if not success:
        sys.exit(1)  # Exit with error code if initialization failed
