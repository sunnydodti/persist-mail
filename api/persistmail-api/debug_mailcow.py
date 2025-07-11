#!/usr/bin/env python3
"""
Simple Mailcow connection test.
"""

import asyncio
import httpx
import sys
import os

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

async def test_mailcow_connection():
    """Simple connection test to Mailcow API."""
    
    api_url = settings.MAILCOW_API_URL
    api_key = settings.MAILCOW_API_KEY
    
    print(f"Testing connection to: {api_url}")
    print(f"Using API key: {api_key[:10]}...")
    
    headers = {
        "X-API-Key": api_key,
        "Content-Type": "application/json"
    }
    
    # Test different endpoints
    test_endpoints = [
        "/api/v1/get/mailq/all",  # This is shown working in the screenshot
        "/api/v1/get/status/containers",
        "/api/v1/get/domain/all",
        "/api/v1/get/status/version"
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for endpoint in test_endpoints:
            url = f"{api_url}{endpoint}"
            print(f"\nTesting: {url}")
            
            try:
                response = await client.get(url, headers=headers)
                print(f"Status: {response.status_code}")
                
                if response.status_code == 200:
                    print("✓ Success!")
                    try:
                        data = response.json()
                        print(f"Response: {str(data)[:200]}...")
                    except:
                        print(f"Response text: {response.text[:200]}...")
                    break
                elif response.status_code == 401:
                    print("❌ Authentication failed - check API key")
                elif response.status_code == 403:
                    print("❌ Forbidden - API key may not have sufficient permissions")
                elif response.status_code == 404:
                    print("❌ Endpoint not found")
                else:
                    print(f"❌ HTTP Error: {response.status_code}")
                    print(f"Response: {response.text[:200]}...")
                    
            except httpx.ConnectError as e:
                print(f"❌ Connection Error: {e}")
            except httpx.TimeoutException as e:
                print(f"❌ Timeout Error: {e}")
            except Exception as e:
                print(f"❌ Unexpected Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_mailcow_connection())
