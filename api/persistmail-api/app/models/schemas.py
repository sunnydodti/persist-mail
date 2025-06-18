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

class MailboxCreate(BaseModel):
    email: EmailStr

class DomainResponse(BaseModel):
    domain: str
    is_premium: bool
    
    class Config:
        from_attributes = True
