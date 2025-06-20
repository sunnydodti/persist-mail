@echo off
setlocal enabledelayedexpansion

:: Check AWS CLI
where aws >nul 2>&1
if errorlevel 1 (
    echo "Error: AWS CLI is not installed or not in PATH"
    echo "Please install AWS CLI from: https://aws.amazon.com/cli/"
    exit /b 1
)

:: Check SSH
where ssh >nul 2>&1
if errorlevel 1 (
    echo "Error: SSH is not installed or not in PATH"
    echo "Please install SSH client"
    exit /b 1
)

:: Initialize variables
set "EC2_USER=ec2-user"
set "EC2_HOST=ec2-13-126-52-84.ap-south-1.compute.amazonaws.com"
set "PEM_FILE=..\..\..\credentials\mail-pair.pem"
set "API_KEY=test-key-123"

:: Process parameters
:loop
if "%~1"=="" goto continue
if "%~1"=="-h" (
    set "EC2_HOST=%~2"
    shift
    shift
    goto loop
)
if "%~1"=="-k" (
    set "PEM_FILE=%~2"
    shift
    shift
    goto loop
)
if "%~1"=="-u" (
    set "EC2_USER=%~2"
    shift
    shift
    goto loop
)
if "%~1"=="--api-key" (
    set "API_KEY=%~2"
    shift
    shift
    goto loop
)
shift
goto loop

:continue

:: Validate parameters
if "%EC2_HOST%"=="" (
    echo "Error: EC2 hostname is required"
    echo "Usage: %0 -h hostname -k pemfile [-u username] [--api-key key]"
    exit /b 1
)

if "%PEM_FILE%"=="" (
    echo "Error: PEM file is required"
    echo "Usage: %0 -h hostname -k pemfile [-u username] [--api-key key]"
    exit /b 1
)

echo "Preparing for deployment..."

:: Create deployment directory on EC2
echo "Creating remote directory..."
ssh -i "%PEM_FILE%" -o StrictHostKeyChecking=no "%EC2_USER%@%EC2_HOST%" "mkdir -p ~/mail-admin-api"

:: Copy project files
echo "Copying project files..."
scp -i "%PEM_FILE%" ..\Cargo.toml ..\Cargo.lock "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"
scp -i "%PEM_FILE%" -r ..\src "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"

:: Update service file with API key and copy it
echo "Configuring service with API key..."
powershell -Command "(Get-Content ..\mail-admin-api.service) -replace 'ADMIN_API_KEY=.*', 'ADMIN_API_KEY=%API_KEY%' | Set-Content ..\mail-admin-api.service.tmp"
scp -i "%PEM_FILE%" ..\mail-admin-api.service.tmp "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/mail-admin-api.service"
del ..\mail-admin-api.service.tmp

:: Copy deployment scripts
scp -i "%PEM_FILE%" deploy.sh install_rust.sh start.sh "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"

:: Install system dependencies only if not already installed (suppress most output)
echo "Installing system dependencies..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && if [ ! -f ~/.cargo/bin/cargo ]; then sudo yum clean all >/dev/null 2>&1 && sudo yum -q update -y && sudo yum -q groupinstall -y 'Development Tools' && sudo yum -q install -y --allowerasing gcc gcc-c++ make cmake openssl-devel pkg-config git; fi"

:: Install Rust and build project (only install if not present)
echo "Installing Rust and building project..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && bash install_rust.sh && source $HOME/.cargo/env && cargo build --release"

:: Verify the binary exists and set permissions
echo "Verifying build..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && test -f target/release/mail-admin-api && chmod +x target/release/mail-admin-api"

:: Deploy and start service
echo "Setting up service..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && sudo cp mail-admin-api.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable mail-admin-api && sudo systemctl restart mail-admin-api"

:: Configure firewall for both docker and public zones
echo "Configuring firewall..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "sudo firewall-cmd --zone=docker --add-port=5000/tcp --permanent >/dev/null 2>&1; sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent >/dev/null 2>&1; sudo firewall-cmd --reload >/dev/null 2>&1"

:: Wait for service to start
timeout /t 5 /nobreak >nul

:: Check service status
echo "Checking service status..."
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "sudo systemctl status mail-admin-api --no-pager"

:: Test API health endpoint (using EC2 hostname)
echo "Testing API health endpoint..."
curl -X GET http://%EC2_HOST%:5000/health

:: Run full test suite
echo "Testing deployed API..."
call %~dp0test_api.cmd -h %EC2_HOST% -k %API_KEY%

echo "Deployment complete"
echo "You can test the API using:"
echo curl -X GET http://%EC2_HOST%:5000/health
echo curl -X POST -H "X-API-Key: %API_KEY%" http://%EC2_HOST%:5000/mailbox/testuser
