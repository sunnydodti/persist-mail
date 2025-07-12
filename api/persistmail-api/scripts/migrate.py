#!/usr/bin/env python3
"""
Database migration and setup script for PersistMail API
"""

import sys
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Add the parent directory to sys.path to import app modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
from app.models.models import Base, Domain
from app.db.session import engine

def create_tables():
    """Create all database tables."""
    print("📊 Creating database tables...")
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully")
        return True
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

def check_database_connection():
    """Test database connectivity."""
    print("🔍 Testing database connection...")
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            result.fetchone()
        print("✅ Database connection successful")
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def migrate_database():
    """Run database migrations if needed."""
    print("🔄 Running database migrations...")
    
    if not check_database_connection():
        return False
    
    if not create_tables():
        return False
        
    # Initialize with default domain
    from app.db.init_db import init_db
    if init_db():
        print("✅ Database migration completed successfully")
        return True
    else:
        print("❌ Database migration failed")
        return False

def backup_database():
    """Create a backup of the current database (SQLite only)."""
    if "sqlite" in settings.DATABASE_URL.lower():
        import shutil
        from datetime import datetime
        
        db_path = settings.DATABASE_URL.replace("sqlite:///", "").replace("sqlite://", "")
        if os.path.exists(db_path):
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = f"{db_path}.backup_{timestamp}"
            try:
                shutil.copy2(db_path, backup_path)
                print(f"✅ Database backed up to: {backup_path}")
                return True
            except Exception as e:
                print(f"⚠️ Warning: Database backup failed: {e}")
                return False
    else:
        print("⚠️ Database backup skipped (not SQLite)")
        return True

def main():
    """Main migration function."""
    print("🗄️ Starting database migration for PersistMail API...")
    
    # Create backup first
    backup_database()
    
    # Run migration
    if migrate_database():
        print("\n🎉 Database migration completed successfully!")
        return 0
    else:
        print("\n❌ Database migration failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
