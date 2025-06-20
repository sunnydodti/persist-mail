import smtplib
import ssl
from fastapi import HTTPException
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class MailboxService:
    def __init__(self, smtp_host: str, smtp_port: int, admin_email: str, admin_password: str):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.admin_email = admin_email
        self.admin_password = admin_password

    async def create_mailbox(self, email: str) -> bool:
        """
        Create a new mailbox by sending a welcome email.
        This will automatically create the mailbox on the mail server.
        """
        try:
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE

            with smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, context=context) as server:
                server.login(self.admin_email, self.admin_password)
                
                # Create welcome message
                message = MIMEMultipart()
                message["From"] = self.admin_email
                message["To"] = email
                message["Subject"] = "Welcome to Your Temporary Mailbox"
                
                body = """
                Welcome to your temporary mailbox!
                
                This mailbox has been created and will be available for the next 24 hours.
                You can now receive emails at this address.
                
                Best regards,
                PersistMail Team
                """
                
                message.attach(MIMEText(body, "plain"))
                server.send_message(message)
                
                return True
                
        except Exception as e:
            print(f"Error creating mailbox: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create mailbox: {str(e)}"
            )
