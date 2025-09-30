# Kill Existing Processes Script
Write-Host "Killing existing processes..." -ForegroundColor Yellow

# Kill Node.js processes
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Found $($nodeProcesses.Count) Node.js processes. Killing them..." -ForegroundColor Red
    $nodeProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
} else {
    Write-Host "No Node.js processes found." -ForegroundColor Green
}

# Kill Redis processes
$redisProcesses = Get-Process -Name "redis-server" -ErrorAction SilentlyContinue
if ($redisProcesses) {
    Write-Host "Found $($redisProcesses.Count) Redis processes. Killing them..." -ForegroundColor Red
    $redisProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
} else {
    Write-Host "No Redis processes found." -ForegroundColor Green
}

# Kill any processes using our ports
$ports = @(3000, 3001, 3002, 3003, 6379)
foreach ($port in $ports) {
    $processes = netstat -ano | findstr ":$port"
    if ($processes) {
        Write-Host "Found processes using port $port. Killing them..." -ForegroundColor Red
        $processes | ForEach-Object {
            $parts = $_ -split '\s+'
            $processId = $parts[-1]
            if ($processId -match '^\d+$') {
                try {
                    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "Could not kill process $processId" -ForegroundColor Yellow
                }
            }
        }
    }
}

Write-Host "Process cleanup completed!" -ForegroundColor Green
Start-Sleep -Seconds 2
