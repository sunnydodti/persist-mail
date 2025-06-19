@echo "off"
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

:: Test health endpoint
echo "Testing health endpoint..."
curl -X GET http://%EC2_HOST%:5000/health
echo.
echo.

:: Test creating a mailbox
echo "Testing mailbox creation..."
curl -X POST -H "X-API-Key: %API_KEY%" http://%EC2_HOST%:5000/mailbox/testuser
echo.
echo.

:: Test with invalid API key
echo "Testing with invalid API key..."
curl -X POST -H "X-API-Key: invalid-key" http://%EC2_HOST%:5000/mailbox/testuser
echo.
echo.

:: Test with invalid username
echo "Testing with invalid username..."
curl -X POST -H "X-API-Key: %API_KEY%" http://%EC2_HOST%:5000/mailbox/test@invalid
echo.
