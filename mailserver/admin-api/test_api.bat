@echo off
setlocal enabledelayedexpansion

:: Set your API key here (should match the one in run_test.bat)
set API_KEY=test-key-123

:: Check if a username was provided
if "%~1"=="" (
    echo Usage: test_api.bat username
    echo Example: test_api.bat testuser
    exit /b 1
)

:: Make the API call
echo Testing API with username: %~1
curl -X POST -H "X-API-Key: %API_KEY%" http://127.0.0.1:5000/mailbox/%~1

echo.
