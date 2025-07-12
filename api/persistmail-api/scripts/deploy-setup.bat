@echo off
REM Pre-deployment script for PersistMail API (Windows)

echo 🚀 Starting PersistMail API pre-deployment setup...

REM Check if we're in the right directory
if not exist "main.py" (
    echo ❌ Error: main.py not found. Please run this script from the API directory.
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo ❌ Error: .env file not found.
    echo 📋 Please copy env.example to .env and configure your settings:
    echo    copy env.example .env
    exit /b 1
)

echo ✅ Environment file found

REM Check if virtual environment exists
if not exist "env" (
    echo 📦 Creating virtual environment...
    python -m venv env
)

REM Activate virtual environment
call env\Scripts\activate.bat

echo ✅ Virtual environment activated

REM Upgrade pip
echo 📦 Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo 📦 Installing dependencies...
pip install -r requirements.txt

echo ✅ Dependencies installed

REM Validate environment configuration
echo 🔍 Validating environment configuration...
python -c "from app.core.config import settings; from app.db.init_db import validate_env_settings; error = validate_env_settings(); print(f'❌ Configuration Error: {error}') if error else print('✅ Environment configuration is valid'); exit(1) if error else exit(0)"

if %errorlevel% neq 0 (
    echo Configuration validation failed
    exit /b 1
)

REM Initialize database
echo 🗄️ Initializing database...
python -m app.db.init_db

if %errorlevel% neq 0 (
    echo ❌ Database initialization failed
    exit /b 1
)

echo ✅ Database initialized successfully

REM Test Mailcow connection
echo 🔗 Testing Mailcow API connection...
python -c "import asyncio; from app.services.mailbox_service import MailboxService; async def test(): service = MailboxService(); health = await service.check_mailcow_health(); print('✅ Mailcow API connection successful' if health else '⚠️ Warning: Mailcow API connection failed'); asyncio.run(test())" 2>nul || echo ⚠️ Warning: Mailcow test failed - check configuration

echo.
echo 🎉 Pre-deployment setup completed successfully!
echo.
echo 📋 Next steps:
echo    1. Review your .env configuration
echo    2. Start the API: uvicorn main:app --host 0.0.0.0 --port 8000
echo    3. Test the health endpoint: curl http://localhost:8000/health
echo.
echo 🔗 API Documentation will be available at: http://localhost:8000/docs

pause
