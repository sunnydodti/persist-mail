# Set environment variables for testing
$env:PORT = "5000"
$env:ADMIN_API_KEY = "test-key-123"
$env:RUST_LOG = "debug"

# Function to test the API
function Test-MailboxAPI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "test-key-123"
    )
    
    $headers = @{
        "X-API-Key" = $ApiKey
    }
    
    Write-Host "Testing API with username: $Username"
    try {
        $response = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:5000/mailbox/$Username" -Headers $headers
        Write-Host "Response:" -ForegroundColor Green
        $response | ConvertTo-Json
    }
    catch {
        Write-Host "Error:" -ForegroundColor Red
        Write-Host $_.Exception.Response.StatusCode.value__
        Write-Host $_.Exception.Response.StatusDescription
    }
}

# Build and run the server
Write-Host "Building project..." -ForegroundColor Yellow
cargo build

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nServer is ready to start!" -ForegroundColor Green
    Write-Host "API will be available at http://127.0.0.1:5000"
    Write-Host "Use Ctrl+C to stop the server`n"
    Write-Host "To test in another PowerShell window:" -ForegroundColor Cyan
    Write-Host '. .\test_api.ps1'
    Write-Host 'Test-MailboxAPI -Username "testuser"'
    Write-Host ""
    
    cargo run
}
else {
    Write-Host "Build failed!" -ForegroundColor Red
}
