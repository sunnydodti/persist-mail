#!/usr/bin/env python3
"""
Test script for Mailcow integration.
"""

import asyncio
import sys
import os
from datetime import datetime

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.mailcow_client import MailcowClient
from app.core.config import settings

async def test_mailcow_integration():
    """Test Mailcow API integration."""
    print("Testing Mailcow Integration")
    print("=" * 50)
    
    # Check configuration
    if not settings.MAILCOW_API_URL:
        print("❌ MAILCOW_API_URL not configured")
        return False
        
    if not settings.MAILCOW_API_KEY:
        print("❌ MAILCOW_API_KEY not configured")
        return False
    
    print(f"✓ API URL: {settings.MAILCOW_API_URL}")
    print(f"✓ API Key: {settings.MAILCOW_API_KEY[:10]}...")
    
    # Initialize client
    client = MailcowClient(settings.MAILCOW_API_URL, settings.MAILCOW_API_KEY)
    
    # Test 1: Health check
    print("\n1. Testing Mailcow connection...")
    try:
        health = await client.health_check()
        if health:
            print("✓ Mailcow API is accessible")
        else:
            print("❌ Mailcow API is not accessible")
            return False
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        return False
    
    # Test 2: Check domain
    test_domain = settings.MAIL_DOMAIN or "example.com"
    print(f"\n2. Testing domain check for: {test_domain}")
    try:
        domain_exists = await client.check_domain_exists(test_domain)
        if domain_exists:
            print(f"✓ Domain {test_domain} exists and is active")
        else:
            print(f"❌ Domain {test_domain} not found or inactive")
            print("   Make sure your domain is configured in Mailcow")
    except Exception as e:
        print(f"❌ Domain check failed: {str(e)}")
    
    # Test 3: Create test mailbox
    test_email = f"test-{datetime.now().strftime('%Y%m%d%H%M%S')}@{test_domain}"
    print(f"\n3. Testing mailbox creation: {test_email}")
    try:
        result = await client.create_mailbox(test_email, test_domain, quota=25)
        if result and result.get("created"):
            print(f"✓ Mailbox created successfully")
            print(f"  Email: {result['email']}")
            print(f"  Password: {result['password']}")
            
            # Test 4: Get mailbox info
            print(f"\n4. Testing mailbox info retrieval...")
            info = await client.get_mailbox_info(test_email)
            if info:
                print("✓ Mailbox info retrieved successfully")
                print(f"  Status: Active")
            else:
                print("❌ Could not retrieve mailbox info")
            
            # Test 5: Delete test mailbox
            print(f"\n5. Cleaning up test mailbox...")
            deleted = await client.delete_mailbox(test_email)
            if deleted:
                print("✓ Test mailbox deleted successfully")
            else:
                print("❌ Failed to delete test mailbox")
                
        else:
            print(f"❌ Mailbox creation failed")
            return False
            
    except Exception as e:
        print(f"❌ Mailbox test failed: {str(e)}")
        return False
    
    print("\n" + "=" * 50)
    print("✓ All Mailcow integration tests passed!")
    print("\nYour Mailcow integration is working correctly.")
    print("\nNext steps:")
    print("1. Update your domains in the database to use is_mailcow_managed=True")
    print("2. Test the new API endpoints")
    print("3. Configure cleanup jobs for expired mailboxes")
    
    return True

async def test_database_migration():
    """Test database migration."""
    print("\nTesting Database Migration")
    print("=" * 30)
    
    try:
        from sqlalchemy import create_engine, text
        from app.core.config import settings
        
        engine = create_engine(settings.DATABASE_URL)
        
        with engine.connect() as conn:
            # Check if new columns exist
            result = conn.execute(text("PRAGMA table_info(mailboxes)"))
            columns = [row[1] for row in result.fetchall()]
            
            required_columns = ['password', 'quota_mb', 'quota_used_mb', 'expires_at', 'mailcow_managed']
            missing_columns = [col for col in required_columns if col not in columns]
            
            if missing_columns:
                print(f"❌ Missing columns in mailboxes table: {missing_columns}")
                print("   Run: python migrate_mailcow.py")
                return False
            else:
                print("✓ All required columns exist in mailboxes table")
            
            # Check domains table
            result = conn.execute(text("PRAGMA table_info(domains)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'is_mailcow_managed' not in columns:
                print("❌ Missing is_mailcow_managed column in domains table")
                print("   Run: python migrate_mailcow.py")
                return False
            else:
                print("✓ All required columns exist in domains table")
        
        print("✓ Database migration is complete")
        return True
        
    except Exception as e:
        print(f"❌ Database test failed: {str(e)}")
        return False

async def main():
    """Main test function."""
    print("PersistMail Mailcow Integration Test")
    print("=" * 50)
    
    # Test database first
    db_ok = await test_database_migration()
    if not db_ok:
        print("\n❌ Database migration required before testing Mailcow")
        return
    
    # Test Mailcow integration
    mailcow_ok = await test_mailcow_integration()
    
    if mailcow_ok:
        print("\n🎉 All tests passed! Your Mailcow integration is ready.")
    else:
        print("\n❌ Some tests failed. Please check your configuration.")

if __name__ == "__main__":
    asyncio.run(main())
