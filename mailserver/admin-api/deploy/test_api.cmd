@echo off
setlocal

:: Parse command line arguments
set "EC2_HOST="
set "API_KEY="

:args_loop
if "%1" == "" goto check
if "%1" == "-h" (
    set "EC2_HOST=%2"
    shift
    shift
    goto args_loop
)
if "%1" == "-k" (
    set "API_KEY=%2"
    shift
    shift
    goto args_loop
)
shift
goto args_loop

:check
if "%EC2_HOST%"=="" (
    echo "Error: EC2 host (-h) is required"
    echo "Usage: %~nx0 -h hostname -k api_key"
    echo "Example: %~nx0 -h ec2-12-34-56-78.compute-1.amazonaws.com -k test-key-123"
    exit /b 1
)

if "%API_KEY%"=="" (
    echo "Error: API key (-k) is required"
    echo "Usage: %~nx0 -h hostname -k api_key"
    echo "Example: %~nx0 -h ec2-12-34-56-78.compute-1.amazonaws.com -k test-key-123"
    exit /b 1
)

:: First verify Docker and mailserver
echo "Checking Docker and mailserver status..."
ssh -i "E:\projects\repos\persist-mail\credentials\mail-pair.pem" ec2-user@%EC2_HOST% "docker ps | grep mailserver"
if errorlevel 1 (
    echo "Error: mailserver container not running!"
    exit /b 1
)

:: Check setup.sh exists and is executable
echo "Checking setup.sh..."
ssh -i "E:\projects\repos\persist-mail\credentials\mail-pair.pem" ec2-user@%EC2_HOST% "docker exec mailserver test -x /usr/local/bin/setup.sh"
if errorlevel 1 (
    echo "Error: setup.sh not found or not executable!"
    exit /b 1
)

:: Test setup.sh help output
echo "Verifying setup.sh..."
ssh -i "E:\projects\repos\persist-mail\credentials\mail-pair.pem" ec2-user@%EC2_HOST% "docker exec mailserver /usr/local/bin/setup.sh help"
if errorlevel 1 (
    echo "Error: setup.sh help command failed!"
    exit /b 1
)

:: Test health endpoint
echo "Testing health endpoint..."
curl -s -X GET http://%EC2_HOST%:5000/health
echo.
echo.

:: Test creating a mailbox with verbose output
echo "Testing mailbox creation..."
curl -v -X POST -H "X-API-Key: %API_KEY%" http://%EC2_HOST%:5000/mailbox/testuser
echo.
echo.

:: Test with invalid API key
echo "Testing with invalid API key..."
curl -s -X POST -H "X-API-Key: invalid-key" http://%EC2_HOST%:5000/mailbox/testuser
echo.
echo.

:: Test with invalid username
echo "Testing with invalid username..."
curl -s -X POST -H "X-API-Key: %API_KEY%" http://%EC2_HOST%:5000/mailbox/test@invalid
echo.
echo.

:: Show recent logs with --no-pager for better output
echo "Recent service logs:"
ssh -i "E:\projects\repos\persist-mail\credentials\mail-pair.pem" ec2-user@%EC2_HOST% "sudo journalctl -u mail-admin-api -n 50 --no-pager"
