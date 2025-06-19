@echo off
setlocal enabledelayedexpansion

:: Clear existing env vars first
set "PORT="
set "ADMIN_API_KEY="
set "RUST_LOG="

:: Set environment variables for testing
set PORT=5000
set ADMIN_API_KEY=test-key-123
set RUST_LOG=debug

:: Verify environment variables
echo Verifying environment variables:
echo ------------------------------------
echo PORT: %PORT%
if "%PORT%"=="" (
    echo ERROR: PORT is not set!
    exit /b 1
)

echo ADMIN_API_KEY: %ADMIN_API_KEY%
if "%ADMIN_API_KEY%"=="" (
    echo ERROR: ADMIN_API_KEY is not set!
    exit /b 1
)

echo RUST_LOG: %RUST_LOG%
if "%RUST_LOG%"=="" (
    echo ERROR: RUST_LOG is not set!
    exit /b 1
)
echo ------------------------------------
echo All environment variables are set correctly
echo.

:: Build and run in debug mode
echo Building in debug mode...
cargo build

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo Starting server in debug mode...
echo API will be available at http://127.0.0.1:5000
echo Use Ctrl+C to stop the server
echo.
echo Test with:
echo curl -X POST -H "X-API-Key: test-key-123" http://127.0.0.1:5000/mailbox/testuser
echo.

cargo run -- --debug
