from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class EmailBase(BaseModel):
    subject: str
    sender: str
    received_date: datetime
    has_attachments: bool

class EmailList(EmailBase):
    id: str
    snippet: str
    
    class Config:
        from_attributes = True

class EmailDetail(EmailBase):
    id: str
    body_html: Optional[str]
    body_text: str
    attachments: List[str]
    
    class Config:
        from_attributes = True

# Mailbox Schemas
class MailboxCreate(BaseModel):
    domain: Optional[str] = None
    prefix: Optional[str] = None
    quota_mb: Optional[int] = 50
    expiry_hours: Optional[int] = 24

class MailboxCreateResponse(BaseModel):
    email: str
    password: str
    created_at: datetime
    expires_at: Optional[datetime]
    quota_mb: int
    domain_info: dict
    
    class Config:
        from_attributes = True

class MailboxInfoResponse(BaseModel):
    email: str
    domain: str
    created_at: datetime
    expires_at: Optional[datetime]
    last_accessed: datetime
    quota_mb: int
    quota_used_mb: int
    quota_percentage: float
    hours_until_expiry: int
    is_expired: bool
    mailcow_managed: bool
    status: str  # active, expired, suspended
    
    class Config:
        from_attributes = True

class MailboxExtendRequest(BaseModel):
    additional_hours: int

class MailboxExtendResponse(BaseModel):
    email: str
    old_expires_at: Optional[datetime]
    new_expires_at: Optional[datetime]
    additional_hours: int
    total_lifetime_hours: int
    
    class Config:
        from_attributes = True

# Domain Schemas
class DomainResponse(BaseModel):
    id: int
    domain: str
    is_premium: bool
    is_active: bool
    is_mailcow_managed: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class DomainCreateRequest(BaseModel):
    domain: str
    imap_host: str
    imap_port: int
    credentials_key: Optional[str] = None
    is_premium: bool = False
    is_mailcow_managed: bool = True

# System Status Schemas
class SystemStatusResponse(BaseModel):
    status: str
    timestamp: datetime
    uptime_percentage: float
    response_times: dict
    active_domains: int
    total_active_mailboxes: int
    total_emails_processed_today: int
    mailcow_status: dict
    rate_limits: dict
    maintenance: dict
