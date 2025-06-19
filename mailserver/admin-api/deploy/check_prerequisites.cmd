@echo off
setlocal enabledelayedexpansion

:: Colors for Windows CMD
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "RESET=[0m"

echo %GREEN%Checking prerequisites for deployment...%RESET%

:: Check AWS CLI
echo Checking AWS CLI...
where aws >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%AWS CLI not found!%RESET%
    echo Please install AWS CLI from: https://aws.amazon.com/cli/
    echo After installing, run 'aws configure' to set up your credentials
    exit /b 1
) else (
    echo %GREEN%AWS CLI found%RESET%
    aws --version
)

:: Check SSH
echo.
echo Checking SSH...
where ssh >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%SSH not found!%RESET%
    echo Please install OpenSSH Client from Windows Settings ^> Apps ^> Optional Features
    exit /b 1
) else (
    echo %GREEN%SSH found%RESET%
    ssh -V
)

:: Check AWS Configuration
echo.
echo Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%AWS credentials not configured!%RESET%
    echo Please run 'aws configure' to set up your credentials
    exit /b 1
) else (
    echo %GREEN%AWS credentials found%RESET%
)

:: Check Rust installation
echo.
echo Checking Rust installation...
where rustc >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %YELLOW%Rust not found! Installing...%RESET%
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
) else (
    echo %GREEN%Rust found%RESET%
    rustc --version
)

:: All checks passed
echo.
echo %GREEN%All prerequisites are satisfied!%RESET%
echo.
echo To deploy to EC2, use:
echo deploy_to_ec2.cmd -h your-ec2-host -k path\to\your-key.pem -u ubuntu
echo.
echo Example:
echo deploy_to_ec2.cmd -h ec2-12-34-56-78.compute-1.amazonaws.com -k C:\Keys\my-key.pem -u ubuntu

exit /b 0
