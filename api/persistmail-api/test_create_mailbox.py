#!/usr/bin/env python3
"""
Test mailbox creation with the actual domain.
"""

import asyncio
import sys
import os
from datetime import datetime

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.mailcow_client import MailcowClient
from app.core.config import settings

async def test_mailbox_creation():
    """Test creating a mailbox on test.persistmail.site domain."""
    
    print("Testing Mailbox Creation")
    print("=" * 40)
    
    # Initialize client
    client = MailcowClient(settings.MAILCOW_API_URL, settings.MAILCOW_API_KEY)
    
    # Test domain
    test_domain = "test.persistmail.site"
    
    # Test 1: Health check
    print("1. Testing Mailcow connection...")
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
    print(f"\n2. Checking domain: {test_domain}")
    try:
        domain_exists = await client.check_domain_exists(test_domain)
        if domain_exists:
            print(f"✓ Domain {test_domain} exists and is active")
        else:
            print(f"⚠️  Domain {test_domain} not found or inactive")
            print("   Proceeding anyway...")
    except Exception as e:
        print(f"❌ Domain check failed: {str(e)}")
    
    # Test 3: Create test mailbox
    timestamp = datetime.now().strftime('%H%M%S')
    test_email = f"test-{timestamp}@{test_domain}"
    print(f"\n3. Creating test mailbox: {test_email}")
    
    try:
        result = await client.create_mailbox(test_email, test_domain, quota=25)
        if result and result.get("created"):
            print("✓ Mailbox created successfully!")
            print(f"  Email: {result['email']}")
            print(f"  Password: {result['password']}")
            print(f"  Quota: {result['quota']}MB")
            
            # Test 4: Try to get mailbox info
            print(f"\n4. Getting mailbox info...")
            try:
                info = await client.get_mailbox_info(test_email)
                if info:
                    print("✓ Mailbox info retrieved successfully")
                    print(f"  Info type: {type(info)}")
                    if isinstance(info, list) and len(info) > 0:
                        mailbox_data = info[0]
                        print(f"  Quota: {mailbox_data.get('quota', 'N/A')}")
                        print(f"  Active: {mailbox_data.get('active', 'N/A')}")
                    elif isinstance(info, dict):
                        print(f"  Quota: {info.get('quota', 'N/A')}")
                        print(f"  Active: {info.get('active', 'N/A')}")
                else:
                    print("⚠️  Could not retrieve mailbox info (this might be normal)")
            except Exception as e:
                print(f"⚠️  Mailbox info retrieval failed: {str(e)}")
            
            # Test 5: Delete test mailbox
            print(f"\n5. Cleaning up test mailbox...")
            try:
                deleted = await client.delete_mailbox(test_email)
                if deleted:
                    print("✓ Test mailbox deleted successfully")
                else:
                    print("⚠️  Could not delete test mailbox (you may need to delete manually)")
            except Exception as e:
                print(f"⚠️  Deletion failed: {str(e)}")
                print(f"   Please manually delete: {test_email}")
            
            return True
            
        else:
            print("❌ Mailbox creation failed")
            print(f"   Result: {result}")
            return False
            
    except Exception as e:
        print(f"❌ Mailbox creation failed: {str(e)}")
        return False

if __name__ == "__main__":
    asyncio.run(test_mailbox_creation())
