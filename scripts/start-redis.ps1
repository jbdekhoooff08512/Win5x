# Start Redis Server Script
Write-Host "Starting Redis Server..." -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green

# Navigate to redis directory
Set-Location "redis"

# Check if Redis server executable exists
if (-not (Test-Path "redis-server.exe")) {
    Write-Host "Error: redis-server.exe not found in redis directory!" -ForegroundColor Red
    Write-Host "Please make sure Redis is properly installed." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait for 1 second to ensure clean startup
Start-Sleep -Seconds 1

# Start Redis server
Write-Host "Starting Redis server..." -ForegroundColor Cyan
try {
    .\redis-server.exe redis.windows.conf
} catch {
    Write-Host "Error starting Redis server: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
