from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, create_engine, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta

Base = declarative_base()

class Domain(Base):
    __tablename__ = "domains"
    
    id = Column(Integer, primary_key=True, index=True)
    domain = Column(String, unique=True, index=True, nullable=False)
    imap_host = Column(String, nullable=False)
    imap_port = Column(Integer, nullable=False)
    credentials_key = Column(String, nullable=True)  # Nullable for Mailcow domains
    is_premium = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    is_mailcow_managed = Column(Boolean, default=True)  # New field for Mailcow integration
    created_at = Column(DateTime, default=datetime.utcnow)
    
    mailboxes = relationship("Mailbox", back_populates="domain")

class Mailbox(Base):
    __tablename__ = "mailboxes"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(Text, nullable=True)  # Individual password for Mailcow
    domain_id = Column(Integer, ForeignKey("domains.id"))
    quota_mb = Column(Integer, default=50)  # Mailbox quota in MB
    quota_used_mb = Column(Integer, default=0)  # Used quota in MB
    expires_at = Column(DateTime, nullable=True)  # When mailbox expires
    mailcow_managed = Column(Boolean, default=True)  # Whether managed by Mailcow
    last_accessed = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    domain = relationship("Domain", back_populates="mailboxes")

    @property
    def quota_percentage(self) -> float:
        """Calculate quota usage percentage."""
        if self.quota_mb == 0:
            return 0.0
        return (self.quota_used_mb / self.quota_mb) * 100

    @property
    def is_expired(self) -> bool:
        """Check if mailbox has expired."""
        if not self.expires_at:
            return False
        return datetime.utcnow() > self.expires_at

    @property
    def hours_until_expiry(self) -> int:
        """Get hours until mailbox expires."""
        if not self.expires_at:
            return 0
        delta = self.expires_at - datetime.utcnow()
        return max(0, int(delta.total_seconds() / 3600))

    def set_expiry(self, hours: int) -> None:
        """Set the expiration time for the mailbox."""
        self.expires_at = datetime.utcnow() + timedelta(hours=hours)
