@echo off
setlocal enabledelayedexpansion

:: Set environment variables for testing
set PORT=5000
set ADMIN_API_KEY=test-key-123
set RUST_LOG=debug

:: Display current settings
echo Current configuration:
echo PORT: %PORT%
echo ADMIN_API_KEY: %ADMIN_API_KEY%
echo RUST_LOG: %RUST_LOG%
echo.

:: Build the project
echo Building project...
cargo build

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

:: Run the server
echo Starting server with test configuration...
echo API will be available at http://127.0.0.1:5000
echo Use Ctrl+C to stop the server
echo.
echo Test with:
echo curl -X POST -H "X-API-Key: test-key-123" http://127.0.0.1:5000/mailbox/testuser
echo.

cargo run
