from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.models import models, schemas
from app.services.email_service import EmailService
from app.core.config import settings
import random
import string

email_router = APIRouter()

def generate_random_mailbox(domain: str, length: int = 10) -> str:
    """Generate a random mailbox name."""
    chars = string.ascii_lowercase + string.digits
    random_str = ''.join(random.choice(chars) for _ in range(length))
    return f"{random_str}@{domain}"

@email_router.get("/emails/{mailbox}", response_model=List[schemas.EmailList])
async def get_emails(
    mailbox: str,
    hours: int = Query(default=settings.DEFAULT_HOURS_RETENTION, le=72),
    limit: int = Query(default=settings.DEFAULT_EMAIL_LIMIT, le=settings.MAX_EMAIL_LIMIT),
    db: Session = Depends(get_db)
):
    """
    Retrieve emails for a given mailbox.
    If mailbox doesn't exist, it will be created automatically.
    """
    # Check if mailbox exists, if not create it
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == mailbox).first()
    if not db_mailbox:
        # Get the first active domain
        domain = db.query(models.Domain).filter(models.Domain.is_active == True).first()
        if not domain:
            raise HTTPException(status_code=500, detail="No active domains available")
        
        # Create new mailbox
        db_mailbox = models.Mailbox(email=mailbox, domain_id=domain.id)
        db.add(db_mailbox)
        db.commit()
        db.refresh(db_mailbox)

    # Update last accessed
    db_mailbox.last_accessed = db.func.now()
    db.commit()    # Initialize email service
    email_service = EmailService(
        db_mailbox.domain.imap_host,
        db_mailbox.domain.imap_port,
        mailbox,  # Full email address as IMAP username
        db_mailbox.domain.credentials_key  # Shared secret
    )
    
    # Fetch emails
    return await email_service.fetch_emails(hours=hours, limit=limit)

@email_router.get("/email/{message_id}", response_model=schemas.EmailDetail)
async def get_email_detail(
    message_id: str,
    mailbox: str = Query(...),
    db: Session = Depends(get_db)
):
    """
    Retrieve detailed information about a specific email.
    """
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == mailbox).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")

    email_service = EmailService(
        db_mailbox.domain.imap_host,
        db_mailbox.domain.imap_port,
        mailbox,
        db_mailbox.domain.credentials_key
    )
    
    email_detail = await email_service.get_email(message_id)
    if not email_detail:
        raise HTTPException(status_code=404, detail="Email not found")
        
    return email_detail

@email_router.get("/domains", response_model=List[schemas.DomainResponse])
async def get_domains(db: Session = Depends(get_db)):
    """
    Retrieve list of available domains.
    """
    domains = db.query(models.Domain).filter(models.Domain.is_active == True).all()
    return domains
