# Render deployment - minimal health check
import os
import sys

# Basic health check for Render
def health_check():
    try:
        # Just check if we can import our main modules
        from app.core.config import settings
        print("✅ Configuration loaded")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

if __name__ == "__main__":
    if health_check():
        sys.exit(0)
    else:
        sys.exit(1)
