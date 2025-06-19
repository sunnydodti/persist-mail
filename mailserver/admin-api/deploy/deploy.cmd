@echo off
setlocal

set EC2_HOST=none
set PEM_FILE=none
set EC2_USER=ubuntu

:parse
if "%1"=="" goto check
if "%1"=="-h" set EC2_HOST=%2& shift & shift & goto parse
if "%1"=="-k" set PEM_FILE=%2& shift & shift & goto parse
if "%1"=="-u" set EC2_USER=%2& shift & shift & goto parse
shift
goto parse

:check
if %EC2_HOST%==none (
    echo Error: EC2 host (-h) is required
    echo Usage: %~nx0 -h hostname -k pemfile [-u username]
    exit /b 1
)

if %PEM_FILE%==none (
    echo Error: PEM file (-k) is required
    echo Usage: %~nx0 -h hostname -k pemfile [-u username]
    exit /b 1
)

echo Host: %EC2_HOST%
echo Key:  %PEM_FILE%
echo User: %EC2_USER%

:: Create temp directory
set TEMP_DIR=%TEMP%\mail-admin-deploy-%RANDOM%
mkdir "%TEMP_DIR%"
if errorlevel 1 (
    echo Failed to create temporary directory
    exit /b 1
)

:: Copy files
xcopy /Y /Q "..\target\release\mail-admin-api.exe" "%TEMP_DIR%\" >nul
xcopy /Y /Q /E ".\*" "%TEMP_DIR%\" >nul

:: Setup remote
ssh -i "%PEM_FILE%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_HOST% "mkdir -p ~/mail-admin-api"

:: Copy to EC2
scp -i "%PEM_FILE%" -r "%TEMP_DIR%\*" "%EC2_USER%@%EC2_HOST%:~/mail-admin-api/"

:: Run deployment
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_HOST% "cd ~/mail-admin-api && sudo chmod +x *.sh && sudo ./install_rust.sh && sudo ./deploy.sh && sudo ./setup_monitoring.sh"

:: Cleanup
rd /s /q "%TEMP_DIR%"

echo Deployment complete!
echo Test with: curl -X POST -H "X-API-Key: your-api-key" http://%EC2_HOST%:5000/mailbox/testuser

exit /b 0
