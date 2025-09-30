# Start Backend Server Script
Write-Host "Starting Win5x Backend Server..." -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Navigate to backend directory
Set-Location "packages/backend"

# Check if Redis is running
Write-Host "Checking Redis status..." -ForegroundColor Yellow
$redisProcess = Get-Process -Name "redis-server" -ErrorAction SilentlyContinue
if (-not $redisProcess) {
    Write-Host "Warning: Redis server not found. Make sure Redis is running." -ForegroundColor Red
    Write-Host "You can start Redis from the redis directory with: .\redis-server.exe" -ForegroundColor Yellow
}

# Wait for 1 second to ensure clean startup
Start-Sleep -Seconds 1

# Start the backend server
$backendPort = if ($env:BACKEND_PORT) { $env:BACKEND_PORT } else { 3001 }
Write-Host "Starting backend server on port $backendPort..." -ForegroundColor Cyan

# Ensure child process sees PORT
$env:PORT = $backendPort
try {
    pnpm dev
} catch {
    Write-Host "Error starting backend server: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
