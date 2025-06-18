from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import email_router
from app.core.config import settings

app = FastAPI(
    title="PersistMail API",
    description="Temporary Email Service API",
    version="1.0.0"
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

@app.get("/")
async def root():
    return {"message": "Welcome to PersistMail API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
