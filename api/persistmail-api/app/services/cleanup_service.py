import asyncio
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.models import Mailbox
from app.services.mailcow_client import MailcowClient
from app.core.config import settings

class MailboxCleanupService:
    def __init__(self):
        self.mailcow_client = MailcowClient(
            settings.MAILCOW_API_URL,
            settings.MAILCOW_API_KEY
        )

    async def cleanup_expired_mailboxes(self) -> int:
        """
        Clean up expired mailboxes from both database and Mailcow.
        
        Returns:
            Number of mailboxes cleaned up
        """
        db = SessionLocal()
        cleaned_count = 0
        
        try:
            # Find expired mailboxes
            now = datetime.utcnow()
            expired_mailboxes = db.query(Mailbox).filter(
                Mailbox.expires_at <= now,
                Mailbox.mailcow_managed == True
            ).all()
            
            for mailbox in expired_mailboxes:
                try:
                    # Delete from Mailcow
                    success = await self.mailcow_client.delete_mailbox(mailbox.email)
                    
                    if success:
                        # Delete from database
                        db.delete(mailbox)
                        cleaned_count += 1
                        print(f"Cleaned up expired mailbox: {mailbox.email}")
                    else:
                        print(f"Failed to delete mailbox from Mailcow: {mailbox.email}")
                        
                except Exception as e:
                    print(f"Error cleaning up mailbox {mailbox.email}: {str(e)}")
                    continue
            
            db.commit()
            
        except Exception as e:
            print(f"Error during cleanup: {str(e)}")
            db.rollback()
        finally:
            db.close()
            
        return cleaned_count

    async def cleanup_old_mailboxes_by_last_access(self, hours: int = 72) -> int:
        """
        Clean up mailboxes that haven't been accessed for a specified time.
        
        Args:
            hours: Number of hours since last access to consider for cleanup
            
        Returns:
            Number of mailboxes cleaned up
        """
        db = SessionLocal()
        cleaned_count = 0
        
        try:
            # Find mailboxes not accessed for specified hours
            cutoff_time = datetime.utcnow() - timedelta(hours=hours)
            old_mailboxes = db.query(Mailbox).filter(
                Mailbox.last_accessed <= cutoff_time,
                Mailbox.mailcow_managed == True
            ).all()
            
            for mailbox in old_mailboxes:
                try:
                    # Delete from Mailcow
                    success = await self.mailcow_client.delete_mailbox(mailbox.email)
                    
                    if success:
                        # Delete from database
                        db.delete(mailbox)
                        cleaned_count += 1
                        print(f"Cleaned up inactive mailbox: {mailbox.email}")
                    else:
                        print(f"Failed to delete inactive mailbox from Mailcow: {mailbox.email}")
                        
                except Exception as e:
                    print(f"Error cleaning up inactive mailbox {mailbox.email}: {str(e)}")
                    continue
            
            db.commit()
            
        except Exception as e:
            print(f"Error during inactive cleanup: {str(e)}")
            db.rollback()
        finally:
            db.close()
            
        return cleaned_count

    async def update_quota_usage(self) -> int:
        """
        Update quota usage for all active mailboxes.
        
        Returns:
            Number of mailboxes updated
        """
        db = SessionLocal()
        updated_count = 0
        
        try:
            # Get all active Mailcow-managed mailboxes
            active_mailboxes = db.query(Mailbox).filter(
                Mailbox.mailcow_managed == True
            ).all()
            
            for mailbox in active_mailboxes:
                try:
                    # Get quota usage from Mailcow
                    quota_info = await self.mailcow_client.get_mailbox_quota_usage(mailbox.email)
                    
                    if quota_info:
                        # Convert bytes to MB
                        used_mb = quota_info["used"] // (1024 * 1024)
                        mailbox.quota_used_mb = used_mb
                        updated_count += 1
                        
                except Exception as e:
                    print(f"Error updating quota for {mailbox.email}: {str(e)}")
                    continue
            
            db.commit()
            
        except Exception as e:
            print(f"Error during quota update: {str(e)}")
            db.rollback()
        finally:
            db.close()
            
        return updated_count

# Background task runner
async def run_cleanup_tasks():
    """Run periodic cleanup tasks."""
    cleanup_service = MailboxCleanupService()
    
    while True:
        try:
            print("Starting mailbox cleanup tasks...")
            
            # Clean up expired mailboxes
            expired_cleaned = await cleanup_service.cleanup_expired_mailboxes()
            print(f"Cleaned up {expired_cleaned} expired mailboxes")
            
            # Clean up inactive mailboxes (older than 72 hours)
            inactive_cleaned = await cleanup_service.cleanup_old_mailboxes_by_last_access(72)
            print(f"Cleaned up {inactive_cleaned} inactive mailboxes")
            
            # Update quota usage
            quota_updated = await cleanup_service.update_quota_usage()
            print(f"Updated quota for {quota_updated} mailboxes")
            
            print("Cleanup tasks completed")
            
        except Exception as e:
            print(f"Error in cleanup tasks: {str(e)}")
        
        # Wait 1 hour before next cleanup
        await asyncio.sleep(3600)

if __name__ == "__main__":
    # Run cleanup tasks
    asyncio.run(run_cleanup_tasks())
