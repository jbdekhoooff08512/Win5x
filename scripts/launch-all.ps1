# Launch All Win5x Services Script
Write-Host "=========================================" -ForegroundColor Green
Write-Host "    Win5x Complete System Launcher" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Determine LAN IP for mobile testing display
function Get-LanIp {
    try {
        $ip = Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.*' -and $_.IPAddress -notlike '0.*' } |
            Sort-Object -Property InterfaceMetric |
            Select-Object -First 1 -ExpandProperty IPAddress
        if (-not $ip) { $ip = (Test-Connection -ComputerName (hostname) -Count 1).IPv4Address.IPAddressToString }
        return $ip
    } catch { return $null }
}

$LAN_IP = Get-LanIp

# Step 1: Clean up existing processes
Write-Host "Step 1: Cleaning up existing processes..." -ForegroundColor Yellow
& "$PSScriptRoot\kill-processes.ps1"

# Step 2: Wait for cleanup to complete
Write-Host "Step 2: Waiting for cleanup to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Step 3: Start Redis
Write-Host "Step 3: Starting Redis server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-redis.ps1" -WindowStyle Normal

# Wait for Redis to start
Write-Host "Waiting for Redis to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 4: Start Backend
Write-Host "Step 4: Starting Backend server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-backend.ps1" -WindowStyle Normal

# Wait for backend to be ready
Write-Host "Waiting for Backend to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 5: Start Frontend services
Write-Host "Step 5: Starting Frontend services..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\..'; .\scripts\start-frontend.ps1" -WindowStyle Normal

# Wait for frontend services
Write-Host "Waiting for Frontend services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Readiness checks
$ErrorActionPreference = 'SilentlyContinue'

function Test-UrlReady {
    param(
        [string]$Url,
        [int]$Retries = 20,
        [int]$DelaySeconds = 1
    )
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { return $true }
        } catch {}
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

function Test-TcpPort {
    param(
        [string]$Host,
        [int]$Port,
        [int]$Retries = 20,
        [int]$DelaySeconds = 1
    )
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $iar = $client.BeginConnect($Host, $Port, $null, $null)
            $wait = $iar.AsyncWaitHandle.WaitOne(1000, $false)
            if ($wait -and $client.Connected) { $client.EndConnect($iar); $client.Close(); return $true }
            $client.Close()
        } catch {}
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

Write-Host "Checking Redis readiness on 6379..." -ForegroundColor Yellow
if (-not (Test-TcpPort -Host '127.0.0.1' -Port 6379)) { Write-Host "Redis did not become ready in time." -ForegroundColor Red }

Write-Host "Checking Backend readiness on http://localhost:3001/health..." -ForegroundColor Yellow
if (-not (Test-UrlReady -Url 'http://localhost:3001/health')) { Write-Host "Backend did not become ready in time." -ForegroundColor Red }

Write-Host "Checking Admin readiness on http://localhost:3000..." -ForegroundColor Yellow
if (-not (Test-UrlReady -Url 'http://localhost:3000')) { Write-Host "Admin did not become ready in time." -ForegroundColor DarkYellow }

Write-Host "Checking User readiness on http://localhost:3002..." -ForegroundColor Yellow
if (-not (Test-UrlReady -Url 'http://localhost:3002')) { Write-Host "User did not become ready in time." -ForegroundColor DarkYellow }

# Step 6: Display final status
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "    All Services Started Successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Application URLs:" -ForegroundColor Cyan
Write-Host "   • Admin Panel:  http://localhost:3000" -ForegroundColor White
Write-Host "   • User Panel:   http://localhost:3002" -ForegroundColor White
Write-Host "   • Backend API:  http://localhost:3001" -ForegroundColor White
Write-Host "   • Redis:        localhost:6379" -ForegroundColor White
Write-Host ""
if ($LAN_IP) {
    Write-Host "Mobile (same Wi‑Fi) URLs:" -ForegroundColor Cyan
    Write-Host ("   • Admin Panel:  http://{0}:3000" -f $LAN_IP) -ForegroundColor White
    Write-Host ("   • User Panel:   http://{0}:3002" -f $LAN_IP) -ForegroundColor White
    Write-Host ("   • Backend API:  http://{0}:3001" -f $LAN_IP) -ForegroundColor White
    Write-Host "" 
}
Write-Host "Notes for mobile testing:" -ForegroundColor Cyan
Write-Host "   • Ensure the phone is on the same Wi‑Fi network." -ForegroundColor White
Write-Host "   • If pages don't load, check Windows Firewall and allow Node/Vite." -ForegroundColor White
Write-Host "" 
Write-Host "Default Admin Credentials:" -ForegroundColor Cyan
Write-Host "   • Username: admin" -ForegroundColor White
Write-Host "   • Password: Admin123!" -ForegroundColor White
Write-Host ""
Write-Host "Notes:" -ForegroundColor Cyan
Write-Host "   • Each service is running in its own terminal window" -ForegroundColor White
Write-Host "   • Close individual terminal windows to stop specific services" -ForegroundColor White
Write-Host "   • Use Ctrl+C in any terminal to stop that service" -ForegroundColor White
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green

# Wait for user input before closing
Write-Host "Press any key to close this launcher..." -ForegroundColor Yellow
try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    Pause
}
