#!/usr/bin/env python3
"""
Health check script for PersistMail API
Use this to verify the deployment is working correctly
"""

import sys
import os
import asyncio
import httpx
from typing import Dict, Any

# Add the parent directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

async def check_api_health(base_url: str = "http://localhost:8000") -> Dict[str, Any]:
    """Check if the API is responding."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{base_url}/health")
            if response.status_code == 200:
                return {"status": "✅ API is healthy", "data": response.json()}
            else:
                return {"status": f"⚠️ API returned {response.status_code}", "data": response.text}
    except Exception as e:
        return {"status": f"❌ API health check failed: {e}", "data": None}

async def check_mailcow_connection() -> Dict[str, Any]:
    """Check Mailcow API connectivity."""
    try:
        from app.services.mailbox_service import MailboxService
        service = MailboxService()
        health = await service.check_mailcow_health()
        if health:
            return {"status": "✅ Mailcow connection healthy", "data": "Connected"}
        else:
            return {"status": "❌ Mailcow connection failed", "data": "Check API credentials"}
    except Exception as e:
        return {"status": f"❌ Mailcow check failed: {e}", "data": None}

def check_database_connection() -> Dict[str, Any]:
    """Check database connectivity."""
    try:
        from app.db.session import engine
        from sqlalchemy import text
        
        with engine.connect() as conn:
            result = conn.execute(text("SELECT COUNT(*) FROM domains"))
            count = result.scalar()
            return {"status": "✅ Database connection healthy", "data": f"{count} domains configured"}
    except Exception as e:
        return {"status": f"❌ Database check failed: {e}", "data": None}

def check_environment_config() -> Dict[str, Any]:
    """Check environment configuration."""
    try:
        from app.db.init_db import validate_env_settings
        error = validate_env_settings()
        if error:
            return {"status": f"❌ Configuration error: {error}", "data": None}
        else:
            return {"status": "✅ Environment configuration valid", "data": "All required settings present"}
    except Exception as e:
        return {"status": f"❌ Config check failed: {e}", "data": None}

async def run_health_checks(api_url: str = "http://localhost:8000") -> bool:
    """Run all health checks."""
    print("🏥 Running PersistMail API health checks...\n")
    
    checks = [
        ("Environment Configuration", check_environment_config()),
        ("Database Connection", check_database_connection()),
        ("Mailcow API Connection", await check_mailcow_connection()),
        ("API Health", await check_api_health(api_url)),
    ]
    
    all_passed = True
    
    for name, result in checks:
        status = result["status"]
        data = result["data"]
        
        print(f"📋 {name}: {status}")
        if data:
            print(f"   └─ {data}")
        
        if "❌" in status:
            all_passed = False
        
        print()
    
    if all_passed:
        print("🎉 All health checks passed! Your deployment is ready.")
    else:
        print("⚠️ Some health checks failed. Please review the issues above.")
    
    return all_passed

async def main():
    """Main health check function."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Health check for PersistMail API")
    parser.add_argument("--url", default="http://localhost:8000", 
                       help="API base URL (default: http://localhost:8000)")
    
    args = parser.parse_args()
    
    success = await run_health_checks(args.url)
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
