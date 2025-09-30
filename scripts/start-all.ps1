# Start All Win5x Services Script
Write-Host "Starting All Win5x Services..." -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Function to check if a port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# Function to wait for a service to be ready
function Wait-ForService {
    param([int]$Port, [string]$ServiceName, [int]$Timeout = 30)
    Write-Host "Waiting for $ServiceName to be ready on port $Port..." -ForegroundColor Yellow
    $startTime = Get-Date
    while ((Get-Date) -lt ($startTime.AddSeconds($Timeout))) {
        if (Test-Port $Port) {
            Write-Host "$ServiceName is ready!" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 1
    }
    Write-Host "Timeout waiting for $ServiceName" -ForegroundColor Red
    return $false
}

# Kill any existing processes on our ports
Write-Host "Checking for existing processes..." -ForegroundColor Yellow
$ports = @(3000, 3002, 3003, 6379)
foreach ($port in $ports) {
    if (Test-Port $port) {
        Write-Host "Port $port is already in use. Please stop any existing services." -ForegroundColor Red
        Write-Host "You can use: netstat -ano | findstr :$port" -ForegroundColor Yellow
    }
}

# Start Redis first
Write-Host "Starting Redis server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-redis.ps1" -WindowStyle Normal

# Wait for Redis to start
Start-Sleep -Seconds 3

# Start Backend
Write-Host "Starting Backend server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-backend.ps1" -WindowStyle Normal

# Wait for backend to be ready
if (Wait-ForService -Port 3003 -ServiceName "Backend" -Timeout 30) {
    # Start Frontend services
    Write-Host "Starting Frontend services..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-frontend.ps1" -WindowStyle Normal
    
    # Wait for frontend services
    Start-Sleep -Seconds 5
    
    Write-Host "All services started successfully!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Admin Panel: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "User Panel:  http://localhost:3002" -ForegroundColor Cyan
    Write-Host "Backend API: http://localhost:3003" -ForegroundColor Cyan
    Write-Host "Redis:       localhost:6379" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Green
} else {
    Write-Host "Failed to start backend service. Please check the logs." -ForegroundColor Red
}

Write-Host "Press any key to exit this launcher..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
