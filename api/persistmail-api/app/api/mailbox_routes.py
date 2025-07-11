"""
Mailbox management routes for Mailcow integration.
"""

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Dict, Any, List
from datetime import datetime, timedelta
import random
import string

from app.db.session import get_db
from app.models import models, schemas
from app.services.mailcow_client import MailcowClient
from app.services.mailcow_email_service import MailcowEmailService
from app.core.config import settings

mailbox_router = APIRouter()

def get_mailcow_client() -> MailcowClient:
    """Get configured Mailcow client."""
    if not settings.MAILCOW_ENABLED:
        raise HTTPException(
            status_code=503, 
            detail="Mailcow integration is disabled"
        )
    
    if not settings.MAILCOW_API_URL or not settings.MAILCOW_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="Mailcow integration not properly configured"
        )
    
    return MailcowClient(settings.MAILCOW_API_URL, settings.MAILCOW_API_KEY)

def generate_random_prefix(length: int = 8) -> str:
    """Generate a random prefix for mailbox names."""
    chars = string.ascii_lowercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

@mailbox_router.post("/mailbox", response_model=schemas.MailboxCreateResponse)
async def create_temporary_mailbox(
    request: schemas.MailboxCreate,
    db: Session = Depends(get_db),
    mailcow: MailcowClient = Depends(get_mailcow_client)
):
    """
    Create a new temporary mailbox with Mailcow integration.
    """
    try:
        # Get domain - either specified or auto-select
        if request.domain:
            domain = db.query(models.Domain).filter(
                models.Domain.domain == request.domain,
                models.Domain.is_active == True,
                models.Domain.is_mailcow_managed == True
            ).first()
            if not domain:
                raise HTTPException(status_code=400, detail="Domain not found or not available")
        else:
            # Auto-select first available domain
            domain = db.query(models.Domain).filter(
                models.Domain.is_active == True,
                models.Domain.is_mailcow_managed == True
            ).first()
            if not domain:
                raise HTTPException(status_code=500, detail="No active domains available")
        
        # Generate email address
        prefix = request.prefix if request.prefix else generate_random_prefix()
        email_address = f"{prefix}@{domain.domain}"
        
        # Check if mailbox already exists
        existing_mailbox = db.query(models.Mailbox).filter(
            models.Mailbox.email == email_address
        ).first()
        if existing_mailbox:
            raise HTTPException(status_code=409, detail="Mailbox already exists")
        
        # Validate quota
        quota_mb = min(request.quota_mb or settings.MAILCOW_DEFAULT_QUOTA_MB, settings.MAILCOW_MAX_QUOTA_MB)
        
        # Validate expiry
        expiry_hours = min(request.expiry_hours or settings.DEFAULT_MAILBOX_EXPIRY_HOURS, settings.MAX_MAILBOX_EXPIRY_HOURS)
        expires_at = datetime.utcnow() + timedelta(hours=expiry_hours)
        
        # Create mailbox in Mailcow
        mailcow_result = await mailcow.create_mailbox(
            email=email_address,
            domain=domain.domain,
            quota=quota_mb
        )
        
        # Store in database
        db_mailbox = models.Mailbox(
            email=email_address,
            password=mailcow_result["password"],
            domain_id=domain.id,
            quota_mb=quota_mb,
            quota_used_mb=0,
            expires_at=expires_at,
            mailcow_managed=True
        )
        
        db.add(db_mailbox)
        db.commit()
        db.refresh(db_mailbox)
        
        return schemas.MailboxCreateResponse(
            email=email_address,
            password=mailcow_result["password"],
            created_at=db_mailbox.created_at,
            expires_at=expires_at,
            quota_mb=quota_mb,
            domain_info={
                "domain": domain.domain,
                "is_premium": domain.is_premium
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"Error creating mailbox: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create mailbox")

@mailbox_router.get("/mailbox/{email}/info", response_model=schemas.MailboxInfoResponse)
async def get_mailbox_info(
    email: str,
    db: Session = Depends(get_db),
    mailcow: MailcowClient = Depends(get_mailcow_client)
):
    """
    Get detailed mailbox information including usage statistics.
    """
    # Get from database
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == email).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    # Get real-time quota usage from Mailcow
    quota_usage = await mailcow.get_mailbox_quota_usage(email)
    if quota_usage:
        # Update quota usage in database
        db_mailbox.quota_used_mb = quota_usage["used"] // (1024 * 1024)
        db.commit()
    
    # Determine status
    status = "active"
    if db_mailbox.is_expired:
        status = "expired"
    elif not db_mailbox.domain.is_active:
        status = "suspended"
    
    return schemas.MailboxInfoResponse(
        email=db_mailbox.email,
        domain=db_mailbox.domain.domain,
        created_at=db_mailbox.created_at,
        expires_at=db_mailbox.expires_at,
        last_accessed=db_mailbox.last_accessed,
        quota_mb=db_mailbox.quota_mb,
        quota_used_mb=db_mailbox.quota_used_mb,
        quota_percentage=db_mailbox.quota_percentage,
        hours_until_expiry=db_mailbox.hours_until_expiry,
        is_expired=db_mailbox.is_expired,
        mailcow_managed=db_mailbox.mailcow_managed,
        status=status
    )

@mailbox_router.patch("/mailbox/{email}/extend", response_model=schemas.MailboxExtendResponse)
async def extend_mailbox_expiry(
    email: str,
    request: schemas.MailboxExtendRequest,
    db: Session = Depends(get_db)
):
    """
    Extend mailbox expiry time (premium feature).
    """
    # Get mailbox
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == email).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    # Check if already expired
    if db_mailbox.is_expired:
        raise HTTPException(status_code=409, detail="Cannot extend expired mailbox")
    
    # Validate extension request
    if request.additional_hours <= 0 or request.additional_hours > 48:
        raise HTTPException(status_code=400, detail="Invalid extension hours (1-48)")
    
    # Calculate new expiry
    old_expires_at = db_mailbox.expires_at
    new_expires_at = old_expires_at + timedelta(hours=request.additional_hours)
    
    # Check maximum lifetime
    total_lifetime = new_expires_at - db_mailbox.created_at
    if total_lifetime.total_seconds() > settings.MAX_MAILBOX_EXPIRY_HOURS * 3600:
        raise HTTPException(
            status_code=400, 
            detail=f"Maximum lifetime of {settings.MAX_MAILBOX_EXPIRY_HOURS} hours exceeded"
        )
    
    # Update database
    db_mailbox.expires_at = new_expires_at
    db.commit()
    
    return schemas.MailboxExtendResponse(
        email=email,
        old_expires_at=old_expires_at,
        new_expires_at=new_expires_at,
        additional_hours=request.additional_hours,
        total_lifetime_hours=int(total_lifetime.total_seconds() / 3600)
    )

@mailbox_router.delete("/mailbox/{email}")
async def delete_mailbox(
    email: str,
    db: Session = Depends(get_db),
    mailcow: MailcowClient = Depends(get_mailcow_client)
):
    """
    Delete a temporary mailbox immediately.
    """
    # Get mailbox from database
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == email).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    try:
        # Delete from Mailcow
        await mailcow.delete_mailbox(email)
        
        # Remove from database
        db.delete(db_mailbox)
        db.commit()
        
        return {
            "message": f"Mailbox {email} deleted successfully",
            "deleted_at": datetime.utcnow(),
            "emails_deleted": "unknown",  # Mailcow doesn't provide this info
            "quota_freed_mb": db_mailbox.quota_used_mb
        }
        
    except Exception as e:
        db.rollback()
        print(f"Error deleting mailbox: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete mailbox")

@mailbox_router.post("/mailbox/cleanup")
async def cleanup_expired_mailboxes(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    mailcow: MailcowClient = Depends(get_mailcow_client)
):
    """
    Cleanup expired mailboxes (admin endpoint).
    """
    
    async def cleanup_task():
        """Background task to cleanup expired mailboxes."""
        try:
            # Find expired mailboxes
            expired_mailboxes = db.query(models.Mailbox).filter(
                models.Mailbox.expires_at < datetime.utcnow(),
                models.Mailbox.mailcow_managed == True
            ).all()
            
            deleted_count = 0
            freed_quota = 0
            
            for mailbox in expired_mailboxes:
                try:
                    # Delete from Mailcow
                    await mailcow.delete_mailbox(mailbox.email)
                    
                    # Track statistics
                    freed_quota += mailbox.quota_used_mb
                    deleted_count += 1
                    
                    # Remove from database
                    db.delete(mailbox)
                    
                except Exception as e:
                    print(f"Failed to delete expired mailbox {mailbox.email}: {str(e)}")
                    continue
            
            db.commit()
            print(f"Cleanup completed: {deleted_count} mailboxes deleted, {freed_quota}MB freed")
            
        except Exception as e:
            print(f"Cleanup task failed: {str(e)}")
            db.rollback()
    
    # Run cleanup in background
    background_tasks.add_task(cleanup_task)
    
    return {"message": "Cleanup task started"}

# Update emails endpoint to use Mailcow authentication
@mailbox_router.get("/emails/{mailbox}", response_model=List[schemas.EmailList])
async def get_emails_mailcow(
    mailbox: str,
    hours: int = 24,
    limit: int = 25,
    db: Session = Depends(get_db)
):
    """
    Retrieve emails using Mailcow individual authentication.
    """
    # Get mailbox info
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == mailbox).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    if not db_mailbox.password:
        raise HTTPException(status_code=500, detail="Mailbox password not available")
    
    # Update last accessed
    db_mailbox.last_accessed = func.now()
    db.commit()
    
    # Use Mailcow email service with individual credentials
    email_service = MailcowEmailService(
        imap_host=db_mailbox.domain.imap_host,
        imap_port=db_mailbox.domain.imap_port,
        email_address=mailbox,
        password=db_mailbox.password
    )
    
    # Fetch emails
    return await email_service.fetch_emails(hours=hours, limit=limit)

@mailbox_router.get("/email/{message_id}", response_model=schemas.EmailDetail)
async def get_email_detail_mailcow(
    message_id: str,
    mailbox: str,
    db: Session = Depends(get_db)
):
    """
    Get email detail using Mailcow individual authentication.
    """
    # Get mailbox info
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == mailbox).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    if not db_mailbox.password:
        raise HTTPException(status_code=500, detail="Mailbox password not available")
    
    # Use Mailcow email service
    email_service = MailcowEmailService(
        imap_host=db_mailbox.domain.imap_host,
        imap_port=db_mailbox.domain.imap_port,
        email_address=mailbox,
        password=db_mailbox.password
    )
    
    email_detail = await email_service.get_email(message_id)
    if not email_detail:
        raise HTTPException(status_code=404, detail="Email not found")
    
    return email_detail
