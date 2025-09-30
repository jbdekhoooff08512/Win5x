# PostgreSQL Installation Script for Windows
# This script downloads and installs PostgreSQL on Windows

Write-Host "PostgreSQL Installation Script for Windows" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# Set variables
$postgresVersion = "16.1"
$postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64.exe"
$installerPath = "$env:TEMP\postgresql-installer.exe"
$installDir = "C:\Program Files\PostgreSQL\16"
$dataDir = "C:\Program Files\PostgreSQL\16\data"
$port = "5432"

Write-Host "Downloading PostgreSQL $postgresVersion..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $postgresUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "Download completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download PostgreSQL installer: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
Write-Host "Please follow the installation wizard and use these recommended settings:" -ForegroundColor Cyan
Write-Host "- Installation Directory: $installDir" -ForegroundColor Cyan
Write-Host "- Data Directory: $dataDir" -ForegroundColor Cyan
Write-Host "- Port: $port" -ForegroundColor Cyan
Write-Host "- Superuser Password: Choose a strong password and remember it!" -ForegroundColor Cyan
Write-Host "- Locale: Default" -ForegroundColor Cyan

# Run the installer
Start-Process -FilePath $installerPath -ArgumentList "--mode unattended --superpassword postgres123 --servicename postgresql --serviceaccount postgres --servicepassword postgres123" -Wait

# Add PostgreSQL to PATH
$postgresBin = "$installDir\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notlike "*$postgresBin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$postgresBin", "Machine")
    Write-Host "Added PostgreSQL to system PATH" -ForegroundColor Green
}

# Refresh environment variables
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")

Write-Host "PostgreSQL installation completed!" -ForegroundColor Green
Write-Host "Please restart your terminal/PowerShell to use PostgreSQL commands." -ForegroundColor Yellow

# Clean up installer
Remove-Item $installerPath -Force

Write-Host "Installation script completed. Please restart your terminal and run the database setup script." -ForegroundColor Green
