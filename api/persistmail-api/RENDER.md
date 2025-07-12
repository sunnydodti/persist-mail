# Render deployment configuration
# Copy these settings to your Render service configuration

# Build Command:
./render-build.sh

# Start Command:
uvicorn main:app --host 0.0.0.0 --port $PORT

# Environment Variables to set in Render dashboard:

# Required - Mailcow Integration
MAILCOW_API_URL=https://test.smtp.persistmail.site
MAILCOW_API_KEY=76D365-BAEF98-4D26D2-5D0856-8D35CC

# Required - Domain Configuration  
MAIL_DOMAIN=test.persist.site
IMAP_HOST=test.smtp.persist.site
IMAP_SECRET=your-shared-mailbox-password  # All mailboxes use this password

# Database (Render will provide this)
DATABASE_URL=postgresql://user:pass@host:port/db

# Security
SSL_VERIFY_CERTS=false
CORS_ORIGINS_STR=https://yourdomain.com

# Optional - Defaults are fine
IMAP_PORT=993
MAILCOW_ENABLED=true
DEFAULT_MAILBOX_QUOTA=25
MAILBOX_EXPIRY_HOURS=24
IMAP_TIMEOUT_SECONDS=10
