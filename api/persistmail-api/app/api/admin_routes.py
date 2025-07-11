from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from app.db.session import get_db
from app.models import models, schemas
from app.services.mailbox_service import MailboxService
from app.services.cleanup_service import MailboxCleanupService

admin_router = APIRouter(prefix="/admin", tags=["admin"])

class DomainCreate(BaseModel):
    domain: str
    imap_host: str
    imap_port: int
    credentials_key: str = None  # Optional for Mailcow domains
    is_premium: bool = False
    is_mailcow_managed: bool = True

class DomainUpdate(BaseModel):
    imap_host: str | None = None
    imap_port: int | None = None
    credentials_key: str | None = None
    is_premium: bool | None = None
    is_active: bool | None = None
    is_mailcow_managed: bool | None = None

@admin_router.post("/domains", response_model=schemas.DomainResponse)
async def create_domain(domain: DomainCreate, db: Session = Depends(get_db)):
    """
    Add a new email domain configuration.
    """
    db_domain = models.Domain(
        domain=domain.domain,
        imap_host=domain.imap_host,
        imap_port=domain.imap_port,
        credentials_key=domain.credentials_key,
        is_premium=domain.is_premium,
        is_mailcow_managed=domain.is_mailcow_managed
    )
    db.add(db_domain)
    try:
        db.commit()
        db.refresh(db_domain)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Domain already exists")
    return db_domain

@admin_router.put("/domains/{domain}", response_model=schemas.DomainResponse)
async def update_domain(domain: str, domain_update: DomainUpdate, db: Session = Depends(get_db)):
    """
    Update an existing domain configuration.
    """
    db_domain = db.query(models.Domain).filter(models.Domain.domain == domain).first()
    if not db_domain:
        raise HTTPException(status_code=404, detail="Domain not found")
    
    update_data = domain_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_domain, field, value)
    
    try:
        db.commit()
        db.refresh(db_domain)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Error updating domain")
    return db_domain

@admin_router.get("/domains", response_model=List[schemas.DomainResponse])
async def list_all_domains(db: Session = Depends(get_db)):
    """
    List all domains, including inactive ones.
    """
    return db.query(models.Domain).all()

@admin_router.delete("/domains/{domain}")
async def delete_domain(domain: str, db: Session = Depends(get_db)):
    """
    Soft delete a domain by setting is_active to False.
    """
    db_domain = db.query(models.Domain).filter(models.Domain.domain == domain).first()
    if not db_domain:
        raise HTTPException(status_code=404, detail="Domain not found")
    
    db_domain.is_active = False
    db.commit()
    return {"message": "Domain deactivated successfully"}

@admin_router.get("/mailboxes", response_model=List[schemas.MailboxInfoResponse])
async def list_mailboxes(
    domain: str = None,
    active_only: bool = True,
    db: Session = Depends(get_db)
):
    """
    List all mailboxes, optionally filtered by domain.
    """
    query = db.query(models.Mailbox)
    
    if domain:
        query = query.join(models.Domain).filter(models.Domain.domain == domain)
    
    if active_only:
        # Filter out expired mailboxes
        from datetime import datetime
        query = query.filter(
            (models.Mailbox.expires_at.is_(None)) | 
            (models.Mailbox.expires_at > datetime.utcnow())
        )
    
    mailboxes = query.all()
    
    return [
        schemas.MailboxInfoResponse(
            email=mb.email,
            domain=mb.domain.domain,
            created_at=mb.created_at,
            expires_at=mb.expires_at,
            last_accessed=mb.last_accessed,
            quota_mb=mb.quota_mb,
            quota_used_mb=mb.quota_used_mb,
            is_expired=mb.is_expired(),
            mailcow_managed=mb.mailcow_managed
        )
        for mb in mailboxes
    ]

@admin_router.delete("/mailboxes/{email}")
async def delete_mailbox(email: str, db: Session = Depends(get_db)):
    """
    Delete a specific mailbox from both database and Mailcow.
    """
    db_mailbox = db.query(models.Mailbox).filter(models.Mailbox.email == email).first()
    if not db_mailbox:
        raise HTTPException(status_code=404, detail="Mailbox not found")
    
    # Delete from Mailcow if it's managed by Mailcow
    if db_mailbox.mailcow_managed:
        mailbox_service = MailboxService()
        success = await mailbox_service.delete_mailbox(email)
        
        if not success:
            raise HTTPException(
                status_code=500,
                detail="Failed to delete mailbox from Mailcow"
            )
    
    # Delete from database
    db.delete(db_mailbox)
    db.commit()
    
    return {"message": f"Mailbox {email} deleted successfully"}

@admin_router.post("/cleanup/expired")
async def cleanup_expired_mailboxes():
    """
    Manually trigger cleanup of expired mailboxes.
    """
    cleanup_service = MailboxCleanupService()
    cleaned_count = await cleanup_service.cleanup_expired_mailboxes()
    
    return {
        "message": f"Cleaned up {cleaned_count} expired mailboxes",
        "count": cleaned_count
    }

@admin_router.post("/cleanup/inactive")
async def cleanup_inactive_mailboxes(hours: int = 72):
    """
    Manually trigger cleanup of inactive mailboxes.
    """
    cleanup_service = MailboxCleanupService()
    cleaned_count = await cleanup_service.cleanup_old_mailboxes_by_last_access(hours)
    
    return {
        "message": f"Cleaned up {cleaned_count} inactive mailboxes (>{hours}h)",
        "count": cleaned_count
    }

@admin_router.post("/quota/update")
async def update_quota_usage():
    """
    Update quota usage for all mailboxes from Mailcow.
    """
    cleanup_service = MailboxCleanupService()
    updated_count = await cleanup_service.update_quota_usage()
    
    return {
        "message": f"Updated quota for {updated_count} mailboxes",
        "count": updated_count
    }

@admin_router.get("/health/mailcow")
async def check_mailcow_health():
    """
    Check Mailcow API connectivity.
    """
    mailbox_service = MailboxService()
    is_healthy = await mailbox_service.check_mailcow_health()
    
    return {
        "mailcow_api_healthy": is_healthy,
        "status": "healthy" if is_healthy else "unhealthy"
    }
