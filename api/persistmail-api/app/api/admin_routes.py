from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from app.db.session import get_db
from app.models import models, schemas

admin_router = APIRouter(prefix="/admin", tags=["admin"])

class DomainCreate(BaseModel):
    domain: str
    imap_host: str
    imap_port: int
    credentials_key: str
    is_premium: bool = False

class DomainUpdate(BaseModel):
    imap_host: str | None = None
    imap_port: int | None = None
    credentials_key: str | None = None
    is_premium: bool | None = None
    is_active: bool | None = None

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
        is_premium=domain.is_premium
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
