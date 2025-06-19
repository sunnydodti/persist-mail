@echo off
setlocal enabledelayedexpansion

:: Check AWS CLI
where aws >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed or not in PATH
    echo Please install AWS CLI from: https://aws.amazon.com/cli/
    exit /b 1
)

:: Check SSH
where ssh >nul 2>&1
if errorlevel 1 (
    echo Error: SSH is not installed or not in PATH
    echo Please install SSH client
    exit /b 1
)

:: Initialize variables
set "EC2_USER=ec2-user"
set "EC2_HOST=ec2-13-126-52-84.ap-south-1.compute.amazonaws.com"
set "PEM_FILE=..\..\..\credentials\mail-pair.pem"

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
shift
goto loop

:continue

:: Validate parameters
if "%EC2_HOST%"=="" (
    echo Error: EC2 hostname is required
    echo Usage: %0 -h hostname -k pemfile [-u username]
    exit /b 1
)

if "%PEM_FILE%"=="" (
    echo Error: PEM file is required
    echo Usage: %0 -h hostname -k pemfile [-u username]
    exit /b 1
)

echo Preparing for deployment...

:: Create deployment directory on EC2
echo Creating remote directory...
ssh -i "%PEM_FILE%" -o StrictHostKeyChecking=no "%EC2_USER%@%EC2_HOST%" "mkdir -p ~/mail-admin-api"

:: Copy project files
echo Copying project files...
scp -i "%PEM_FILE%" ..\Cargo.toml ..\Cargo.lock "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"
scp -i "%PEM_FILE%" -r ..\src "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"
scp -i "%PEM_FILE%" ..\mail-admin-api.service "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"
scp -i "%PEM_FILE%" deploy.sh install_rust.sh start.sh "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"

:: Install system dependencies
echo Installing system dependencies...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && sudo yum clean all && sudo yum update -y && sudo yum groupinstall -y 'Development Tools' && sudo yum install -y --allowerasing gcc gcc-c++ make cmake openssl-devel pkg-config git"

:: Install Rust and build project
echo Installing Rust and building project...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && chmod +x *.sh && bash install_rust.sh && source $HOME/.cargo/env && mkdir -p target/release && cargo build --release"

:: Verify the binary exists and set permissions
echo Verifying build...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && if [ ! -f target/release/mail-admin-api ]; then echo 'Binary not found!' && exit 1; fi && chmod +x target/release/mail-admin-api"

:: Deploy and start service
echo Setting up service...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "cd ~/mail-admin-api && sudo cp mail-admin-api.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable mail-admin-api && sudo systemctl restart mail-admin-api"

:: Configure firewall for both docker and public zones
echo Configuring firewall...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent && sudo firewall-cmd --reload"

:: Wait a bit for the service to start
timeout /t 5

:: Verify service is running
echo Checking service status...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "sudo systemctl status mail-admin-api || true"

:: Check logs if service failed
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "sudo journalctl -u mail-admin-api -n 50 --no-pager || true"

:: Check if port is accessible
echo Testing API health endpoint...
ssh -i "%PEM_FILE%" "%EC2_USER%@%EC2_HOST%" "curl -v localhost:5000/health || true"

echo.
echo Deployment complete
echo You can test the API using:
echo curl -X GET http://%EC2_HOST%:5000/health
echo curl -X POST -H "X-API-Key: ^<your-api-key^>" http://%EC2_HOST%:5000/mailbox/testuser

exit /b 0
