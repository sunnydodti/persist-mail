from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import email_router
from app.api.admin_routes import admin_router
from app.api.mailbox_routes import mailbox_router  # New Mailcow routes
from app.core.config import settings

app = FastAPI(
    title="PersistMail API",
    description="Temporary Email Service API with Mailcow Integration",
    version="2.0.0"
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(email_router, prefix="/api/v1", tags=["emails"])
app.include_router(mailbox_router, prefix="/api/v1", tags=["mailboxes"])  # New Mailcow routes
app.include_router(admin_router, prefix="/api/v1", tags=["admin"])

@app.get("/")
async def root():
    return {"message": "Welcome to PersistMail API"}

@app.get("/health")
async def health_check():
    """Health check endpoint for deployment verification."""
    try:
        from app.core.config import settings
        return {
            "status": "healthy",
            "service": "PersistMail API",
            "version": "2.0.0",
            "environment": {
                "database_configured": bool(settings.DATABASE_URL),
                "mailcow_configured": bool(settings.MAILCOW_API_URL and settings.MAILCOW_API_KEY),
                "domain_configured": bool(settings.MAIL_DOMAIN and settings.IMAP_HOST),
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }
