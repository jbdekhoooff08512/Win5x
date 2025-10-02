# Node.js Application Health Check Script
# Run this script to check if your Win5x application is running properly

Write-Host "🔍 Checking Node.js Application Health..." -ForegroundColor Green

$baseUrl = "http://192.168.1.41:3001"

# 1. Check if port is listening
Write-Host "`n1. Checking if port 3001 is listening..." -ForegroundColor Yellow
$portCheck = Test-NetConnection -ComputerName 192.168.1.41 -Port 3001 -InformationLevel Quiet
if ($portCheck) {
    Write-Host "✅ Port 3001 is open" -ForegroundColor Green
} else {
    Write-Host "❌ Port 3001 is not accessible" -ForegroundColor Red
}

# 2. Test health endpoint
Write-Host "`n2. Testing health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 10
    Write-Host "✅ Health endpoint responding:" -ForegroundColor Green
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor Cyan
    Write-Host "   Uptime: $([math]::Round($healthResponse.uptime, 2)) seconds" -ForegroundColor Cyan
    Write-Host "   Timestamp: $($healthResponse.timestamp)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test API endpoint
Write-Host "`n3. Testing API endpoint..." -ForegroundColor Yellow
try {
    $apiResponse = Invoke-RestMethod -Uri "$baseUrl/api/game/current-round" -Method Get -TimeoutSec 10
    Write-Host "✅ API endpoint responding" -ForegroundColor Green
} catch {
    Write-Host "❌ API endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Check Node.js processes
Write-Host "`n4. Checking Node.js processes..." -ForegroundColor Yellow
$nodeProcesses = Get-Process | Where-Object {$_.ProcessName -eq "node"}
if ($nodeProcesses) {
    Write-Host "✅ Found $($nodeProcesses.Count) Node.js process(es)" -ForegroundColor Green
    foreach ($process in $nodeProcesses) {
        Write-Host "   PID: $($process.Id), CPU: $($process.CPU), Memory: $([math]::Round($process.WorkingSet/1MB, 2)) MB" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ No Node.js processes found" -ForegroundColor Red
}

# 5. Check database ports (if running locally)
Write-Host "`n5. Checking database services..." -ForegroundColor Yellow
$postgresCheck = Test-NetConnection -ComputerName localhost -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
$redisCheck = Test-NetConnection -ComputerName localhost -Port 6379 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($postgresCheck) {
    Write-Host "✅ PostgreSQL (port 5432) is running" -ForegroundColor Green
} else {
    Write-Host "⚠️ PostgreSQL (port 5432) not accessible locally" -ForegroundColor Yellow
}

if ($redisCheck) {
    Write-Host "✅ Redis (port 6379) is running" -ForegroundColor Green
} else {
    Write-Host "⚠️ Redis (port 6379) not accessible locally" -ForegroundColor Yellow
}

Write-Host "`n🏁 Health check complete!" -ForegroundColor Green

