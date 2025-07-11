from typing import Dict, Any
from fastapi import HTTPException
from app.services.mailcow_client import MailcowClient
from app.core.config import settings

class MailboxService:
    def __init__(self):
        self.mailcow_client = MailcowClient(
            settings.MAILCOW_API_URL,
            settings.MAILCOW_API_KEY
        )

    async def create_mailbox(self, email: str, domain: str = None) -> Dict[str, Any]:
        """
        Create a new mailbox using Mailcow API.
        
        Args:
            email: Full email address
            domain: Domain name (optional, will be extracted from email if not provided)
            
        Returns:
            Dictionary containing mailbox creation details
        """
        if domain is None:
            domain = email.split('@')[1]
            
        try:
            # Check if domain exists in Mailcow
            domain_exists = await self.mailcow_client.check_domain_exists(domain)
            if not domain_exists:
                raise HTTPException(
                    status_code=400,
                    detail=f"Domain {domain} is not configured in Mailcow"
                )
            
            # Create mailbox
            result = await self.mailcow_client.create_mailbox(
                email=email,
                domain=domain,
                quota=settings.DEFAULT_MAILBOX_QUOTA
            )
            
            return result
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create mailbox: {str(e)}"
            )

    async def delete_mailbox(self, email: str) -> bool:
        """
        Delete a mailbox using Mailcow API.
        
        Args:
            email: Full email address
            
        Returns:
            True if successful
        """
        try:
            return await self.mailcow_client.delete_mailbox(email)
        except Exception as e:
            print(f"Error deleting mailbox {email}: {str(e)}")
            return False

    async def get_mailbox_info(self, email: str) -> Dict[str, Any]:
        """
        Get mailbox information.
        
        Args:
            email: Full email address
            
        Returns:
            Mailbox information
        """
        try:
            return await self.mailcow_client.get_mailbox_info(email)
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get mailbox info: {str(e)}"
            )

    async def check_mailcow_health(self) -> bool:
        """
        Check if Mailcow API is accessible.
        
        Returns:
            True if healthy
        """
        try:
            return await self.mailcow_client.health_check()
        except Exception:
            return False
