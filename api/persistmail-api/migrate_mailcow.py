#!/usr/bin/env python3
"""
Database migration script for Mailcow integration.
This script adds the new columns to existing tables.
"""

import sys
import os
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

def migrate_database():
    """Migrate the database to support Mailcow integration."""
    engine = create_engine(settings.DATABASE_URL)
    
    migrations = [
        # Add new columns to domains table
        "ALTER TABLE domains ADD COLUMN is_mailcow_managed BOOLEAN DEFAULT 1",
        
        # Add new columns to mailboxes table
        "ALTER TABLE mailboxes ADD COLUMN password TEXT",
        "ALTER TABLE mailboxes ADD COLUMN quota_mb INTEGER DEFAULT 50",
        "ALTER TABLE mailboxes ADD COLUMN quota_used_mb INTEGER DEFAULT 0",
        "ALTER TABLE mailboxes ADD COLUMN expires_at DATETIME",
        "ALTER TABLE mailboxes ADD COLUMN mailcow_managed BOOLEAN DEFAULT 1",
        
        # Make credentials_key nullable for Mailcow domains
        # Note: SQLite doesn't support ALTER COLUMN, so we'll handle this differently
    ]
    
    print("Starting database migration for Mailcow integration...")
    
    with engine.connect() as conn:
        for migration in migrations:
            try:
                print(f"Executing: {migration}")
                conn.execute(text(migration))
                conn.commit()
                print("✓ Success")
            except OperationalError as e:
                if "duplicate column name" in str(e).lower() or "already exists" in str(e).lower():
                    print("✓ Column already exists, skipping")
                else:
                    print(f"✗ Error: {e}")
                    return False
            except Exception as e:
                print(f"✗ Unexpected error: {e}")
                return False
    
    print("\nMigration completed successfully!")
    print("\nNext steps:")
    print("1. Update your .env file with Mailcow settings")
    print("2. Configure your domains to use Mailcow")
    print("3. Test the new endpoints")
    
    return True

if __name__ == "__main__":
    migrate_database()
