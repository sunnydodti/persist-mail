# Render Configuration Guide

## 🚀 Render Dashboard Settings

### Service Configuration:
- **Environment:** Python
- **Build Command:** `./build.sh`
- **Start Command:** `./start.sh`
- **Root Directory:** `api/persistmail-api`

### Environment Variables:
Copy these to your Render service environment variables:

```
# Required - Mailcow Integration
MAILCOW_API_URL=https://test.smtp.persistmail.site
MAILCOW_API_KEY=76D365-BAEF98-4D26D2-5D0856-8D35CC

# Required - Domain Configuration  
MAIL_DOMAIN=test.persist.site
IMAP_HOST=test.smtp.persist.site
IMAP_SECRET=b18df737-c3dd-44a4-98e3-85e098d919fb

# Optional - Render will provide DATABASE_URL
# DATABASE_URL=postgresql://user:pass@host:port/db

# Security
SSL_VERIFY_CERTS=false
CORS_ORIGINS_STR=https://yourdomain.com

# Optional - Performance
IMAP_TIMEOUT_SECONDS=10
HTTP_TIMEOUT_SECONDS=30
DEFAULT_MAILBOX_QUOTA=25
MAILBOX_EXPIRY_HOURS=24
```

### Database:
- Add a PostgreSQL database to your service
- Render will automatically set DATABASE_URL

## 🔧 Manual Setup Steps:

1. **Connect GitHub repo** to Render
2. **Set build command:** `./build.sh`
3. **Set start command:** `./start.sh`
4. **Add PostgreSQL database**
5. **Set environment variables** from above
6. **Deploy**

## 🏥 Health Check:
Your service will be available at: `https://your-service.onrender.com/docs`

## 🐛 Troubleshooting:

- Check Render logs for specific errors
- Ensure all environment variables are set
- Verify database connection
- Check API endpoints with `/docs`
