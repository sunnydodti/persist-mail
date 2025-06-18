from typing import List, Optional
from datetime import datetime, timedelta
from imapclient import IMAPClient
from app.models.schemas import EmailList, EmailDetail
from app.core.config import settings
import email
from email.header import decode_header
import base64

class EmailService:
    def __init__(self, imap_host: str, imap_port: int, email: str, shared_secret: str):
        self.imap_host = imap_host
        self.imap_port = imap_port
        self.email = email  # This will be used as the IMAP username
        self.shared_secret = shared_secret  # Common password for all mailboxes    async def connect(self) -> IMAPClient:
        server = IMAPClient(self.imap_host, port=self.imap_port, use_uid=True)
        # Use the full email address as username and shared secret as password
        server.login(self.email, self.shared_secret)
        return server

    async def fetch_emails(self, hours: int = 24, limit: int = 25) -> List[EmailList]:
        server = await self.connect()
        try:
            server.select_folder('INBOX')
            
            # Calculate the date from hours ago
            date_from = (datetime.now() - timedelta(hours=hours)).strftime("%d-%b-%Y")
            messages = server.search(['SINCE', date_from])
            
            # Fetch only the most recent emails up to the limit
            messages = messages[-limit:]
            
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
        finally:
            server.logout()

    async def get_email(self, message_id: str) -> Optional[EmailDetail]:
        server = await self.connect()
        try:
            server.select_folder('INBOX')
            messages = server.fetch([int(message_id)], ['RFC822'])
            
            if not messages:
                return None
                
            msg_data = messages[int(message_id)][b'RFC822']
            email_message = email.message_from_bytes(msg_data)
            
            # Parse email content
            subject = str(decode_header(email_message['subject'])[0][0])
            sender = email_message['from']
            date = datetime.strptime(email_message['date'], "%a, %d %b %Y %H:%M:%S %z")
            
            body_html = None
            body_text = None
            attachments = []
            
            for part in email_message.walk():
                if part.get_content_type() == "text/plain":
                    body_text = part.get_payload(decode=True).decode()
                elif part.get_content_type() == "text/html":
                    body_html = part.get_payload(decode=True).decode()
                elif part.get_filename():
                    attachments.append(part.get_filename())
            
            return EmailDetail(
                id=message_id,
                subject=subject,
                sender=sender,
                received_date=date,
                body_html=body_html,
                body_text=body_text or "No text content",
                has_attachments=bool(attachments),
                attachments=attachments
            )
        finally:
            server.logout()

    def _has_attachments(self, msg_data: dict) -> bool:
        # Simple check based on message size
        return msg_data[b'RFC822.SIZE'] > 50000  # Arbitrary threshold

    def _get_snippet(self, msg_id: int, server: IMAPClient, length: int = 100) -> str:
        # Fetch the message body
        message = server.fetch([msg_id], ['BODY[]'])[msg_id][b'BODY[]']
        email_message = email.message_from_bytes(message)
        
        # Get the first text part
        for part in email_message.walk():
            if part.get_content_type() == "text/plain":
                text = part.get_payload(decode=True).decode()
                return text[:length] + "..." if len(text) > length else text
                
        return "No preview available"
