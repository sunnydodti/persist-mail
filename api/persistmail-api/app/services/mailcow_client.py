import httpx
import secrets
import string
from typing import Optional, Dict, Any
from fastapi import HTTPException
from app.core.config import settings

class MailcowClient:
    def __init__(self, api_url: str, api_key: str):
        self.api_url = api_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            "X-API-Key": api_key,
            "Content-Type": "application/json"
        }

    def generate_password(self, length: Optional[int] = None) -> str:
        """Generate a secure random password for mailbox."""
        if length is None:
            length = settings.PASSWORD_LENGTH
        chars = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(secrets.choice(chars) for _ in range(length))

    async def create_mailbox(self, email: str, domain: str, quota: int = 50) -> Dict[str, Any]:
        """
        Create a new mailbox using Mailcow API.
        
        Args:
            email: Full email address (e.g., test@domain.com)
            domain: Domain name (e.g., domain.com)
            quota: Mailbox quota in MB (default: 50MB)
            
        Returns:
            Dict containing mailbox details including shared password
        """
        local_part = email.split('@')[0]
        # Use shared password from IMAP_SECRET instead of generating random ones
        password = settings.IMAP_SECRET
        
        # Use the exact format from your successful Swagger test
        mailbox_data = {
            "active": "1",
            "domain": domain,
            "local_part": local_part,
            "name": local_part,  # Use local_part as name
            "authsource": "mailcow",
            "password": password,
            "password2": password,
            "quota": str(quota),  # Mailcow expects string, not int
            "force_pw_update": "0",  # Don't force password update for temp mailboxes
            "tls_enforce_in": "0",   # More flexible for temp usage
            "tls_enforce_out": "0"
        }

        try:
            async with httpx.AsyncClient(timeout=settings.HTTP_TIMEOUT_SECONDS) as client:
                response = await client.post(
                    f"{self.api_url}/api/v1/add/mailbox",
                    json=mailbox_data,
                    headers=self.headers
                )
                
                if response.status_code == 200:
                    result = response.json()
                    # Check if any success responses exist
                    success_responses = [r for r in result if r.get("type") == "success"]
                    if success_responses:
                        return {
                            "email": email,
                            "password": password,
                            "quota": quota,
                            "created": True,
                            "mailcow_response": result
                        }
                    else:
                        # Look for error messages
                        error_msgs = [r.get("msg", []) for r in result if r.get("type") == "error"]
                        error_text = str(error_msgs) if error_msgs else f"Unknown error - Full response: {result}"
                        raise HTTPException(
                            status_code=400,
                            detail=f"Mailcow API error: {error_text}"
                        )
                else:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Mailcow API request failed: {response.text}"
                    )
                    
        except httpx.RequestError as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to connect to Mailcow API: {str(e)}"
            )

    async def delete_mailbox(self, email: str) -> bool:
        """
        Delete a mailbox using Mailcow API.
        
        Args:
            email: Full email address to delete
            
        Returns:
            True if successful
        """
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.api_url}/api/v1/delete/mailbox",
                    json=[email],  # Mailcow expects an array
                    headers=self.headers
                )
                
                if response.status_code == 200:
                    result = response.json()
                    # Check for success responses in the array
                    success_responses = [r for r in result if r.get("type") == "success"]
                    return len(success_responses) > 0
                else:
                    print(f"Failed to delete mailbox {email}: {response.text}")
                    return False
                    
        except httpx.RequestError as e:
            print(f"Failed to connect to Mailcow API for deletion: {str(e)}")
            return False

    async def get_mailbox_info(self, email: str) -> Optional[Dict[str, Any]]:
        """
        Get mailbox information using Mailcow API.
        
        Args:
            email: Full email address
            
        Returns:
            Mailbox information or None if not found
        """
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(
                    f"{self.api_url}/api/v1/get/mailbox/{email}",
                    headers=self.headers
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    return None
                    
        except httpx.RequestError:
            return None

    async def get_mailbox_quota_usage(self, email: str) -> Optional[Dict[str, int]]:
        """
        Get mailbox quota usage.
        
        Args:
            email: Full email address
            
        Returns:
            Dict with 'used' and 'total' quota in bytes, or None if not found
        """
        mailbox_info = await self.get_mailbox_info(email)
        if mailbox_info and isinstance(mailbox_info, dict):
            return {
                "used": int(mailbox_info.get("quota_used", 0)),
                "total": int(mailbox_info.get("quota", 0))
            }
        return None

    async def check_domain_exists(self, domain: str) -> bool:
        """
        Check if a domain exists in Mailcow.
        
        Args:
            domain: Domain name to check
            
        Returns:
            True if domain exists and is active
        """
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                # Get all domains and check if our domain is in the list
                response = await client.get(
                    f"{self.api_url}/api/v1/get/domain/all",
                    headers=self.headers
                )
                
                if response.status_code == 200:
                    domains = response.json()
                    if isinstance(domains, list):
                        for domain_info in domains:
                            if (domain_info.get("domain_name") == domain and 
                                domain_info.get("active") in ["1", 1, True]):
                                return True
                    elif isinstance(domains, dict):
                        # Single domain response
                        return (domains.get("domain_name") == domain and 
                               domains.get("active") in ["1", 1, True])
                    return False
                else:
                    return False
                    
        except httpx.RequestError:
            return False

    async def health_check(self) -> bool:
        """
        Check if Mailcow API is accessible.
        
        Returns:
            True if API is accessible
        """
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Use a simple endpoint that should work with any API key
                response = await client.get(
                    f"{self.api_url}/api/v1/get/mailq/all",
                    headers=self.headers
                )
                return response.status_code == 200
        except httpx.RequestError:
            return False
