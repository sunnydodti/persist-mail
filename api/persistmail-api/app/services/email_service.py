from typing import List, Optional
from datetime import datetime, timedelta
from imapclient import IMAPClient
from fastapi import HTTPException
from app.models.schemas import EmailList, EmailDetail
from app.core.config import settings
import email
import ssl
from email.header import decode_header
import base64

class EmailService:
    def __init__(self, imap_host: str, imap_port: int, email: str, password: str):
        self.imap_host = imap_host
        self.imap_port = imap_port
        self.email = email  # Full email address as IMAP username
        self.password = password  # Individual mailbox password (from Mailcow)
        self._server = None

    async def connect(self) -> IMAPClient:
        """Connect to the IMAP server and authenticate."""
        try:
            # Create SSL context that accepts self-signed certificates
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            server = IMAPClient(
                self.imap_host,
                port=self.imap_port,
                ssl_context=context,
                use_uid=True,
                timeout=10  # Add 10 second timeout
            )
            
            server.login(self.email, self.password)
            
            self._server = server
            return self._server
            
        except Exception as e:
            if self._server:
                try:
                    self._server.logout()
                except:
                    pass
            raise HTTPException(
                status_code=500,
                detail=f"Failed to connect to mail server: {str(e)}"
            )

    async def fetch_emails(self, hours: int = 24, limit: int = 25) -> List[EmailList]:
        """Fetch emails from the IMAP server."""
        server = None
        try:
            server = await self.connect()
            server.select_folder('INBOX')
            
            # Calculate the date from hours ago
            date_from = (datetime.now() - timedelta(hours=hours)).strftime("%d-%b-%Y")
            messages = server.search(['SINCE', date_from])
            
            # Fetch only the most recent emails up to the limit
            messages = messages[-limit:] if messages else []
            
            if not messages:
                return []

            email_list = []
            for msg_id, data in server.fetch(messages, ['ENVELOPE', 'FLAGS', 'RFC822.SIZE']).items():
                envelope = data[b'ENVELOPE']
                
                email_data = EmailList(
                    id=str(msg_id),
                    subject=envelope.subject.decode() if envelope.subject else "No Subject",
                    sender=envelope.from_[0].mailbox.decode() + "@" + envelope.from_[0].host.decode(),
                    received_date=envelope.date,
                    has_attachments=self._has_attachments(data),
                    snippet=self._get_snippet(msg_id, server)
                )
                email_list.append(email_data)
                
            return email_list
        except Exception as e:
            print(f"Error fetching emails: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to fetch emails: {str(e)}"
            )
        finally:
            if server and server != self._server:
                try:
                    server.logout()
                except:
                    pass

    def _has_attachments(self, msg_data: dict) -> bool:
        """Check if an email has attachments based on its size."""
        return msg_data[b'RFC822.SIZE'] > 50000  # Arbitrary threshold

    def _get_snippet(self, msg_id: int, server: IMAPClient, length: int = 100) -> str:
        """Get a preview snippet of the email content."""
        try:
            # Fetch the message body
            message = server.fetch([msg_id], ['BODY[]'])[msg_id][b'BODY[]']
            email_message = email.message_from_bytes(message)
            
            # Get the first text part
            for part in email_message.walk():
                if part.get_content_type() == "text/plain":
                    text = part.get_payload(decode=True).decode()
                    return text[:length] + "..." if len(text) > length else text
                    
            return "No preview available"
        except Exception as e:
            print(f"Error getting snippet: {str(e)}")
            return "Preview not available"
