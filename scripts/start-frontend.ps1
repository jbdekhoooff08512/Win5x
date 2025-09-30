# Start Frontend Servers Script
Write-Host "Starting Win5x Frontend Servers..." -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Navigate to root directory
Set-Location "."

# Wait for 1 second to ensure clean startup
Start-Sleep -Seconds 1

# Start frontend applications only (admin and user)
$adminPort = if ($env:ADMIN_PORT) { $env:ADMIN_PORT } else { 3000 }
$userPort = if ($env:USER_PORT) { $env:USER_PORT } else { 3002 }

Write-Host "Starting admin panel on port $adminPort..." -ForegroundColor Cyan
Write-Host "Starting user panel on port $userPort..." -ForegroundColor Cyan

try {
    # Run admin and user dev servers concurrently via workspace filters
    pnpm -w concurrently "pnpm --filter admin dev" "pnpm --filter user dev"
} catch {
    Write-Host "Error starting frontend servers: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
