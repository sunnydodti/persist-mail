"""
Enhanced email service for Mailcow integration.
"""

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

class MailcowEmailService:
    """Enhanced email service for Mailcow integration with individual credentials."""
    
    def __init__(self, imap_host: str, imap_port: int, email_address: str, password: str):
        self.imap_host = imap_host
        self.imap_port = imap_port
        self.email_address = email_address
        self.password = password
        self._server = None

    async def connect(self) -> IMAPClient:
        """Connect to the IMAP server with individual mailbox credentials."""
        try:
            print(f"Connecting to {self.imap_host}:{self.imap_port} for {self.email_address}")
            
            # Create SSL context that accepts self-signed certificates
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            server = IMAPClient(
                self.imap_host,
                port=self.imap_port,
                ssl_context=context,
                use_uid=True
            )
            
            # Use individual mailbox credentials instead of shared secret
            server.login(self.email_address, self.password)
            print(f"Login successful for {self.email_address}")
            
            self._server = server
            return self._server
            
        except Exception as e:
            print(f"Connection/login failed: {str(e)}")
            print(f"Debug info: Host={self.imap_host}, Port={self.imap_port}, Email={self.email_address}")
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
                
                # Handle None values safely
                subject = "No Subject"
                if envelope.subject:
                    subject = envelope.subject.decode() if isinstance(envelope.subject, bytes) else str(envelope.subject)
                
                sender = "Unknown Sender"
                if envelope.from_ and len(envelope.from_) > 0:
                    from_addr = envelope.from_[0]
                    if from_addr.mailbox and from_addr.host:
                        mailbox = from_addr.mailbox.decode() if isinstance(from_addr.mailbox, bytes) else str(from_addr.mailbox)
                        host = from_addr.host.decode() if isinstance(from_addr.host, bytes) else str(from_addr.host)
                        sender = f"{mailbox}@{host}"
                
                email_data = EmailList(
                    id=str(msg_id),
                    subject=subject,
                    sender=sender,
                    received_date=envelope.date or datetime.now(),
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

    async def get_email(self, message_id: str) -> Optional[EmailDetail]:
        """Get detailed email content."""
        server = None
        try:
            server = await self.connect()
            server.select_folder('INBOX')
            
            # Fetch the specific message
            messages = server.fetch([int(message_id)], ['RFC822'])
            if not messages:
                return None
                
            raw_email = messages[int(message_id)][b'RFC822']
            msg = email.message_from_bytes(raw_email)
            
            # Extract email details
            subject = self._decode_header(msg.get('Subject', 'No Subject'))
            sender = msg.get('From', 'Unknown Sender')
            received_date = datetime.now()  # You might want to parse the Date header
            
            # Extract body content
            body_text = ""
            body_html = ""
            attachments = []
            
            if msg.is_multipart():
                for part in msg.walk():
                    content_type = part.get_content_type()
                    content_disposition = str(part.get('Content-Disposition', ''))
                    
                    if 'attachment' in content_disposition:
                        filename = part.get_filename()
                        if filename:
                            attachments.append(filename)
                    elif content_type == 'text/plain':
                        charset = part.get_content_charset() or 'utf-8'
                        body_text = part.get_payload(decode=True).decode(charset, errors='ignore')
                    elif content_type == 'text/html':
                        charset = part.get_content_charset() or 'utf-8'
                        body_html = part.get_payload(decode=True).decode(charset, errors='ignore')
            else:
                # Non-multipart message
                charset = msg.get_content_charset() or 'utf-8'
                content = msg.get_payload(decode=True).decode(charset, errors='ignore')
                content_type = msg.get_content_type()
                
                if content_type == 'text/html':
                    body_html = content
                else:
                    body_text = content
            
            return EmailDetail(
                id=message_id,
                subject=subject,
                sender=sender,
                received_date=received_date,
                has_attachments=len(attachments) > 0,
                body_text=body_text,
                body_html=body_html,
                attachments=attachments
            )
            
        except Exception as e:
            print(f"Error getting email detail: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get email detail: {str(e)}"
            )
        finally:
            if server and server != self._server:
                try:
                    server.logout()
                except:
                    pass

    def _has_attachments(self, data) -> bool:
        """Check if email has attachments (simplified implementation)."""
        # This is a simplified check - you might want to implement a more thorough check
        return False

    def _get_snippet(self, msg_id: int, server: IMAPClient) -> str:
        """Get email snippet/preview."""
        try:
            # Fetch body structure to get a snippet
            messages = server.fetch([msg_id], ['BODY[TEXT]'])
            if messages and msg_id in messages:
                body_data = messages[msg_id].get(b'BODY[TEXT]')
                if body_data:
                    # Try to decode and get first 100 characters
                    try:
                        text = body_data.decode('utf-8', errors='ignore')
                        return text[:100] + "..." if len(text) > 100 else text
                    except:
                        return "Preview not available"
            return "No content"
        except:
            return "Preview not available"

    def _decode_header(self, header_value: str) -> str:
        """Decode email header that might be encoded."""
        if not header_value:
            return ""
        
        try:
            decoded_parts = decode_header(header_value)
            decoded_string = ""
            for part, encoding in decoded_parts:
                if isinstance(part, bytes):
                    if encoding:
                        decoded_string += part.decode(encoding)
                    else:
                        decoded_string += part.decode('utf-8', errors='ignore')
                else:
                    decoded_string += str(part)
            return decoded_string
        except:
            return str(header_value)
