#!/bin/bash
# Pre-deployment script for PersistMail API

set -e  # Exit on any error

echo "🚀 Starting PersistMail API pre-deployment setup..."

# Check if we're in the right directory
if [ ! -f "main.py" ]; then
    echo "❌ Error: main.py not found. Please run this script from the API directory."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found."
    echo "📋 Please copy env.example to .env and configure your settings:"
    echo "   cp env.example .env"
    exit 1
fi

echo "✅ Environment file found"

# Check if virtual environment exists
if [ ! -d "env" ]; then
    echo "📦 Creating virtual environment..."
    python -m venv env
fi

# Activate virtual environment
source env/Scripts/activate 2>/dev/null || source env/bin/activate

echo "✅ Virtual environment activated"

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo "✅ Dependencies installed"

# Validate environment configuration
echo "🔍 Validating environment configuration..."
python -c "
from app.core.config import settings
from app.db.init_db import validate_env_settings

error = validate_env_settings()
if error:
    print(f'❌ Configuration Error: {error}')
    exit(1)
else:
    print('✅ Environment configuration is valid')
"

# Initialize database
echo "🗄️ Initializing database..."
python -m app.db.init_db

if [ $? -eq 0 ]; then
    echo "✅ Database initialized successfully"
else
    echo "❌ Database initialization failed"
    exit 1
fi

# Test Mailcow connection
echo "🔗 Testing Mailcow API connection..."
python -c "
import asyncio
from app.services.mailbox_service import MailboxService

async def test_mailcow():
    try:
        service = MailboxService()
        health = await service.check_mailcow_health()
        if health:
            print('✅ Mailcow API connection successful')
        else:
            print('⚠️  Warning: Mailcow API connection failed')
            print('   Check MAILCOW_API_URL and MAILCOW_API_KEY in .env')
    except Exception as e:
        print(f'⚠️  Warning: Mailcow test failed: {e}')
        print('   Check your Mailcow configuration in .env')

asyncio.run(test_mailcow())
"

echo ""
echo "🎉 Pre-deployment setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Review your .env configuration"
echo "   2. Start the API: uvicorn main:app --host 0.0.0.0 --port 8000"
echo "   3. Test the health endpoint: curl http://localhost:8000/health"
echo ""
echo "🔗 API Documentation will be available at: http://localhost:8000/docs"
