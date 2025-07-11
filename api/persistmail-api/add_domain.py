#!/usr/bin/env python3
"""
Quick script to add new domains to PersistMail
Usage: python add_domain.py <domain> <imap_host> [--premium] [--inactive]
"""
import sys
from app.db.session import SessionLocal
from app.models.models import Domain

def add_domain(domain_name, imap_host, imap_port=993, is_premium=False, is_active=True):
    db = SessionLocal()
    try:
        # Check if domain already exists
        existing = db.query(Domain).filter(Domain.domain == domain_name).first()
        if existing:
            print(f"Domain {domain_name} already exists!")
            return False
        
        # Create new domain
        new_domain = Domain(
            domain=domain_name,
            imap_host=imap_host,
            imap_port=imap_port,
            is_premium=is_premium,
            is_active=is_active,
            is_mailcow_managed=True  # Default to Mailcow managed
        )
        
        db.add(new_domain)
        db.commit()
        print(f"✅ Added domain: {domain_name}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def list_domains():
    db = SessionLocal()
    try:
        domains = db.query(Domain).all()
        print("\n📋 Current domains:")
        for d in domains:
            status = "🟢" if d.is_active else "🔴"
            premium = "💎" if d.is_premium else "🆓"
            mailcow = "📧" if d.is_mailcow_managed else "📪"
            print(f"  {status} {premium} {mailcow} {d.domain} -> {d.imap_host}:{d.imap_port}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python add_domain.py <domain> <imap_host> [--premium] [--inactive]")
        print("   or: python add_domain.py --list")
        sys.exit(1)
    
    if sys.argv[1] == "--list":
        list_domains()
        sys.exit(0)
    
    domain = sys.argv[1]
    imap_host = sys.argv[2]
    is_premium = "--premium" in sys.argv
    is_active = "--inactive" not in sys.argv
    
    add_domain(domain, imap_host, is_premium=is_premium, is_active=is_active)
    list_domains()
