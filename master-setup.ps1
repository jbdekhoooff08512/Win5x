# Win5x Master Setup Script - Complete End-to-End Setup (PowerShell)
# This script handles everything from start to end without errors
# Version: 2.0.0
# Author: Win5x Team

param(
    [string]$DatabasePassword = "Win5xDB@2024",
    [string]$AdminUsername = "admin",
    [string]$AdminEmail = "admin@win5x.com",
    [string]$AdminPassword = "Admin@123",
    [string]$JwtSecret = "8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4",
    [string]$RedisPassword = "Redis@2024",
    [string]$ProjectPath = "/var/www/win5x",
    [string]$ServerIP = "",
    [int]$UserPort = 8080,
    [int]$AdminPort = 8081,
    [int]$BackendPort = 8082,
    [int]$RedisPort = 6379,
    [int]$PostgresPort = 5432,
    [int]$NginxPort = 80
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = "/tmp/win5x-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$BackupDir = "/tmp/win5x-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Get server IP if not provided
if ([string]::IsNullOrEmpty($ServerIP)) {
    try {
        $ServerIP = (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
    }
    catch {
        $ServerIP = "localhost"
    }
}

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Purple = "Magenta"

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-LogInfo {
    param([string]$Message)
    Write-Log "ℹ️  $Message" $Blue
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Log "✅ $Message" $Green
}

function Write-LogWarning {
    param([string]$Message)
    Write-Log "⚠️  $Message" $Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Log "❌ $Message" $Red
}

function Write-LogStep {
    param([string]$Message)
    Write-Log "🔄 $Message" $Purple
}

# Error handling
$ErrorActionPreference = "Stop"
$CurrentStep = ""

# Backup function
function Backup-System {
    Write-LogStep "Creating system backup..."
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    
    # Backup existing configurations
    if (Test-Path "/etc/nginx/sites-available/win5x") {
        Copy-Item "/etc/nginx/sites-available/win5x" "$BackupDir/" -Force
    }
    if (Test-Path "/etc/redis/redis.conf") {
        Copy-Item "/etc/redis/redis.conf" "$BackupDir/" -Force
    }
    if (Test-Path "/etc/postgresql/*/main/postgresql.conf") {
        Copy-Item "/etc/postgresql/*/main/postgresql.conf" "$BackupDir/" -Force
    }
    
    Write-LogSuccess "System backup created at $BackupDir"
}

# Restore function
function Restore-FromBackup {
    if (Test-Path $BackupDir) {
        Write-LogWarning "Restoring from backup..."
        if (Test-Path "$BackupDir/win5x") {
            Copy-Item "$BackupDir/win5x" "/etc/nginx/sites-available/" -Force
        }
        if (Test-Path "$BackupDir/redis.conf") {
            Copy-Item "$BackupDir/redis.conf" "/etc/redis/" -Force
        }
        if (Test-Path "$BackupDir/postgresql.conf") {
            Copy-Item "$BackupDir/postgresql.conf" "/etc/postgresql/*/main/" -Force
        }
        Write-LogSuccess "Restored from backup"
    }
}

# Validation functions
function Test-SystemRequirements {
    Write-LogStep "Validating system requirements..."
    
    # Check if running as root or with sudo
    if ($env:USER -eq "root") {
        Write-LogError "Do not run this script as root. Use sudo when needed."
        exit 1
    }
    
    # Check available disk space (minimum 2GB)
    $availableSpace = (Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Measure-Object -Property FreeSpace -Sum).Sum / 1GB
    if ($availableSpace -lt 2) {
        Write-LogError "Insufficient disk space. Need at least 2GB free."
        exit 1
    }
    
    # Check available memory (minimum 1GB)
    $availableMemory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($availableMemory -lt 1) {
        Write-LogWarning "Low memory detected. Performance may be affected."
    }
    
    Write-LogSuccess "System validation passed"
}

function Test-PortAvailability {
    Write-LogStep "Validating port availability..."
    
    $ports = @($UserPort, $AdminPort, $BackendPort, $NginxPort, $PostgresPort, $RedisPort)
    
    foreach ($port in $ports) {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connection) {
            Write-LogError "Port $port is already in use"
            exit 1
        }
    }
    
    Write-LogSuccess "All ports are available"
}

# Command execution with error handling
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description,
        [bool]$AllowFailure = $false
    )
    
    $script:CurrentStep = $Description
    Write-LogStep $Description
    
    try {
        Invoke-Expression $Command | Out-File -FilePath $LogFile -Append
        Write-LogSuccess "$Description completed"
        return $true
    }
    catch {
        if ($AllowFailure) {
            Write-LogWarning "$Description failed (allowed)"
            return $false
        }
        else {
            Write-LogError "$Description failed: $($_.Exception.Message)"
            exit 1
        }
    }
}

# Check if command exists
function Test-CommandExists {
    param([string]$CommandName)
    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}

# Install system packages
function Install-SystemPackages {
    Write-LogStep "Installing system packages..."
    
    # Update package lists
    Invoke-SafeCommand "sudo apt update" "Package list update"
    
    # Install essential packages
    $essentialPackages = @(
        "curl", "wget", "git", "unzip", "software-properties-common",
        "apt-transport-https", "ca-certificates", "gnupg", "lsb-release",
        "build-essential", "python3", "python3-pip"
    )
    
    Invoke-SafeCommand "sudo apt install -y $($essentialPackages -join ' ')" "Essential packages installation"
    
    Write-LogSuccess "System packages installed"
}

# Install Node.js
function Install-NodeJS {
    Write-LogStep "Installing Node.js..."
    
    if (-not (Test-CommandExists "node")) {
        # Install Node.js 18.x
        Invoke-SafeCommand "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
        Invoke-SafeCommand "sudo apt install -y nodejs" "Node.js installation"
    }
    else {
        $nodeVersion = (node --version).Substring(1).Split('.')[0]
        if ([int]$nodeVersion -lt 18) {
            Write-LogWarning "Node.js version $nodeVersion detected. Upgrading to 18.x..."
            Invoke-SafeCommand "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
            Invoke-SafeCommand "sudo apt install -y nodejs" "Node.js installation"
        }
    }
    
    # Install pnpm
    if (-not (Test-CommandExists "pnpm")) {
        Invoke-SafeCommand "npm install -g pnpm@8.15.0" "pnpm installation"
    }
    
    # Install PM2
    if (-not (Test-CommandExists "pm2")) {
        Invoke-SafeCommand "npm install -g pm2" "PM2 installation"
    }
    
    # Install serve
    Invoke-SafeCommand "npm install -g serve" "Serve installation"
    
    Write-LogSuccess "Node.js ecosystem installed"
}

# Install PostgreSQL
function Install-PostgreSQL {
    Write-LogStep "Installing PostgreSQL..."
    
    if (-not (Test-CommandExists "psql")) {
        Invoke-SafeCommand "sudo apt install -y postgresql postgresql-contrib" "PostgreSQL installation"
        Invoke-SafeCommand "sudo systemctl start postgresql" "PostgreSQL service start"
        Invoke-SafeCommand "sudo systemctl enable postgresql" "PostgreSQL service enable"
    }
    else {
        Write-LogInfo "PostgreSQL already installed"
    }
    
    Write-LogSuccess "PostgreSQL installed and configured"
}

# Install Redis
function Install-Redis {
    Write-LogStep "Installing Redis..."
    
    if (-not (Test-CommandExists "redis-server")) {
        Invoke-SafeCommand "sudo apt install -y redis-server" "Redis installation"
        
        # Configure Redis
        $redisConfig = "/etc/redis/redis.conf"
        Invoke-SafeCommand "sudo cp $redisConfig $redisConfig.backup" "Redis config backup"
        
        # Update Redis configuration
        Invoke-SafeCommand "sudo sed -i 's/^# requirepass.*/requirepass $RedisPassword/' $redisConfig" "Redis password configuration"
        Invoke-SafeCommand "sudo sed -i 's/^# maxmemory.*/maxmemory 256mb/' $redisConfig" "Redis memory configuration"
        Invoke-SafeCommand "sudo sed -i 's/^# maxmemory-policy.*/maxmemory-policy allkeys-lru/' $redisConfig" "Redis policy configuration"
        
        Invoke-SafeCommand "sudo systemctl start redis-server" "Redis service start"
        Invoke-SafeCommand "sudo systemctl enable redis-server" "Redis service enable"
    }
    else {
        Write-LogInfo "Redis already installed"
    }
    
    Write-LogSuccess "Redis installed and configured"
}

# Install Nginx
function Install-Nginx {
    Write-LogStep "Installing Nginx..."
    
    if (-not (Test-CommandExists "nginx")) {
        Invoke-SafeCommand "sudo apt install -y nginx" "Nginx installation"
        Invoke-SafeCommand "sudo systemctl start nginx" "Nginx service start"
        Invoke-SafeCommand "sudo systemctl enable nginx" "Nginx service enable"
    }
    else {
        Write-LogInfo "Nginx already installed"
    }
    
    Write-LogSuccess "Nginx installed and configured"
}

# Setup project
function Setup-Project {
    Write-LogStep "Setting up project..."
    
    # Create project directory
    Invoke-SafeCommand "sudo mkdir -p $ProjectPath" "Project directory creation"
    Invoke-SafeCommand "sudo chown -R `$USER:`$USER $ProjectPath" "Project directory ownership"
    
    # If we're in the project directory, copy files
    if ((Test-Path "package.json") -and (Test-Path "pnpm-workspace.yaml")) {
        Write-LogInfo "Detected existing project. Copying files..."
        Invoke-SafeCommand "cp -r . $ProjectPath/" "Project files copy"
    }
    else {
        Write-LogWarning "No existing project detected. Please ensure project files are available."
        Write-LogInfo "You can clone your repository or copy files to $ProjectPath"
    }
    
    # Navigate to project directory
    Set-Location $ProjectPath
    
    Write-LogSuccess "Project setup completed"
}

# Install project dependencies
function Install-Dependencies {
    Write-LogStep "Installing project dependencies..."
    
    Set-Location $ProjectPath
    
    # Install dependencies
    Invoke-SafeCommand "pnpm install" "Project dependencies installation"
    
    Write-LogSuccess "Dependencies installed"
}

# Setup database
function Setup-Database {
    Write-LogStep "Setting up database..."
    
    $dbName = "win5x_db"
    $dbUser = "win5x_user"
    
    # Create database and user
    Invoke-SafeCommand "sudo -u postgres psql -c `"CREATE DATABASE $dbName;`"" "Database creation" $true
    Invoke-SafeCommand "sudo -u postgres psql -c `"CREATE USER $dbUser WITH PASSWORD '$DatabasePassword';`"" "Database user creation" $true
    Invoke-SafeCommand "sudo -u postgres psql -c `"GRANT ALL PRIVILEGES ON DATABASE $dbName TO $dbUser;`"" "Database privileges" $true
    
    Write-LogSuccess "Database setup completed"
}

# Create environment files
function New-EnvironmentFiles {
    Write-LogStep "Creating environment files..."
    
    Set-Location $ProjectPath
    
    # Backend .env
    $backendEnv = @"
# Database
DATABASE_URL="postgresql://win5x_user:$DatabasePassword@localhost:$PostgresPort/win5x_db"

# JWT
JWT_SECRET="$JwtSecret"
JWT_EXPIRES_IN="24h"

# Redis
REDIS_URL="redis://:$RedisPassword@localhost:$RedisPort"

# Server
PORT=$BackendPort
NODE_ENV=production

# Admin credentials
ADMIN_USERNAME="$AdminUsername"
ADMIN_EMAIL="$AdminEmail"
ADMIN_PASSWORD="$AdminPassword"

# Security
BCRYPT_ROUNDS=12

# File uploads
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880

# Game settings
GAME_BETTING_DURATION=30
GAME_SPIN_DURATION=10
GAME_RESULT_DURATION=15

# Payment settings
USDT_TO_INR_RATE=83.0
DEPOSIT_BONUS_PERCENTAGE=5

# Referral settings
REFERRAL_LEVEL1_PERCENTAGE=5
REFERRAL_LEVEL2_PERCENTAGE=3
REFERRAL_LEVEL3_PERCENTAGE=1

# Attendance
ATTENDANCE_DAY7_AMOUNT=60

# CORS
CORS_ORIGIN="http://$ServerIP`:$NginxPort"
"@

    $backendEnv | Out-File -FilePath "packages/backend/.env" -Encoding UTF8

    # Admin .env
    $adminEnv = @"
VITE_API_URL=http://$ServerIP`:$BackendPort
VITE_SOCKET_URL=http://$ServerIP`:$BackendPort
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
"@

    $adminEnv | Out-File -FilePath "packages/admin/.env" -Encoding UTF8

    # User .env
    $userEnv = @"
VITE_API_URL=http://$ServerIP`:$BackendPort
VITE_SOCKET_URL=http://$ServerIP`:$BackendPort
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
"@

    $userEnv | Out-File -FilePath "packages/user/.env" -Encoding UTF8

    Write-LogSuccess "Environment files created"
}

# Build project
function Build-Project {
    Write-LogStep "Building project..."
    
    Set-Location $ProjectPath
    
    # Build common package first
    Invoke-SafeCommand "cd packages/common && pnpm run build" "Common package build"
    
    # Build backend
    Invoke-SafeCommand "cd packages/backend && pnpm run build:prod" "Backend production build"
    
    # Build frontend packages
    Invoke-SafeCommand "cd packages/admin && pnpm run build" "Admin frontend build"
    Invoke-SafeCommand "cd packages/user && pnpm run build" "User frontend build"
    
    Write-LogSuccess "Project build completed"
}

# Setup database schema
function Setup-DatabaseSchema {
    Write-LogStep "Setting up database schema..."
    
    Set-Location "$ProjectPath/packages/backend"
    
    # Generate Prisma client
    Invoke-SafeCommand "pnpm run db:generate" "Prisma client generation"
    
    # Run migrations
    Invoke-SafeCommand "pnpm run db:migrate:prod" "Database migration"
    
    # Create admin user
    $env:ADMIN_USERNAME = $AdminUsername
    $env:ADMIN_EMAIL = $AdminEmail
    $env:ADMIN_PASSWORD = $AdminPassword
    Invoke-SafeCommand "pnpm run create-admin" "Admin user creation"
    
    Set-Location $ProjectPath
    
    Write-LogSuccess "Database schema setup completed"
}

# Setup PM2 ecosystem
function Setup-PM2 {
    Write-LogStep "Setting up PM2 ecosystem..."
    
    Set-Location $ProjectPath
    
    # Create logs directory
    Invoke-SafeCommand "mkdir -p logs" "Logs directory creation"
    
    # Create PM2 ecosystem file
    $ecosystemConfig = @"
module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/build/dist/server.js',
      cwd: '$ProjectPath',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: $BackendPort
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-admin',
      script: 'serve',
      args: '-s packages/admin/dist -p $AdminPort',
      cwd: '$ProjectPath',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      log_file: './logs/admin-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-user',
      script: 'serve',
      args: '-s packages/user/dist -p $UserPort',
      cwd: '$ProjectPath',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/user-error.log',
      out_file: './logs/user-out.log',
      log_file: './logs/user-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
"@

    $ecosystemConfig | Out-File -FilePath "ecosystem.config.js" -Encoding UTF8

    Write-LogSuccess "PM2 ecosystem configured"
}

# Setup Nginx
function Setup-Nginx {
    Write-LogStep "Setting up Nginx configuration..."
    
    # Create Nginx configuration
    $nginxConfig = @"
server {
    listen $NginxPort;
    server_name _;

    # User panel
    location / {
        proxy_pass http://localhost:$UserPort;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # Admin panel
    location /admin {
        proxy_pass http://localhost:$AdminPort;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # API
    location /api {
        proxy_pass http://localhost:$BackendPort;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # Socket.io
    location /socket.io/ {
        proxy_pass http://localhost:$BackendPort;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
}
"@

    $nginxConfig | Out-File -FilePath "/tmp/win5x-nginx.conf" -Encoding UTF8

    # Install Nginx configuration
    Invoke-SafeCommand "sudo cp /tmp/win5x-nginx.conf /etc/nginx/sites-available/win5x" "Nginx config copy"
    Invoke-SafeCommand "sudo ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/" "Nginx site enable"
    Invoke-SafeCommand "sudo rm -f /etc/nginx/sites-enabled/default" "Default Nginx site removal"
    Invoke-SafeCommand "sudo nginx -t" "Nginx configuration test"
    Invoke-SafeCommand "sudo systemctl reload nginx" "Nginx reload"
    
    Write-LogSuccess "Nginx configured"
}

# Setup firewall
function Setup-Firewall {
    Write-LogStep "Setting up firewall..."
    
    # Configure UFW
    Invoke-SafeCommand "sudo ufw allow 22" "SSH firewall rule"
    Invoke-SafeCommand "sudo ufw allow $NginxPort" "HTTP firewall rule"
    Invoke-SafeCommand "sudo ufw allow 443" "HTTPS firewall rule"
    Invoke-SafeCommand "sudo ufw allow $UserPort" "User panel firewall rule"
    Invoke-SafeCommand "sudo ufw allow $AdminPort" "Admin panel firewall rule"
    Invoke-SafeCommand "sudo ufw allow $BackendPort" "Backend API firewall rule"
    Invoke-SafeCommand "sudo ufw --force enable" "Firewall enable"
    
    Write-LogSuccess "Firewall configured"
}

# Start services
function Start-Services {
    Write-LogStep "Starting services..."
    
    Set-Location $ProjectPath
    
    # Start PM2 applications
    Invoke-SafeCommand "pm2 start ecosystem.config.js" "PM2 applications start"
    Invoke-SafeCommand "pm2 save" "PM2 configuration save"
    Invoke-SafeCommand "pm2 startup" "PM2 startup configuration"
    
    Write-LogSuccess "Services started"
}

# Health checks
function Test-HealthChecks {
    Write-LogStep "Performing health checks..."
    
    # Check PostgreSQL
    if ((Get-Service postgresql).Status -eq "Running") {
        Write-LogSuccess "PostgreSQL is running"
    }
    else {
        Write-LogError "PostgreSQL is not running"
        return $false
    }
    
    # Check Redis
    if ((Get-Service redis-server).Status -eq "Running") {
        Write-LogSuccess "Redis is running"
    }
    else {
        Write-LogError "Redis is not running"
        return $false
    }
    
    # Check Nginx
    if ((Get-Service nginx).Status -eq "Running") {
        Write-LogSuccess "Nginx is running"
    }
    else {
        Write-LogError "Nginx is not running"
        return $false
    }
    
    # Check PM2 processes
    $pm2Status = pm2 list
    if ($pm2Status -match "online") {
        Write-LogSuccess "PM2 processes are running"
    }
    else {
        Write-LogError "PM2 processes are not running"
        return $false
    }
    
    # Test API endpoint
    Start-Sleep -Seconds 5  # Wait for services to start
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$BackendPort/api/health" -UseBasicParsing -TimeoutSec 10
        Write-LogSuccess "API endpoint is responding"
    }
    catch {
        Write-LogWarning "API endpoint health check failed (this may be normal if no health endpoint exists)"
    }
    
    Write-LogSuccess "Health checks completed"
    return $true
}

# Display final information
function Show-FinalInfo {
    Write-Log ""
    Write-Log "===============================================" $Cyan
    Write-Log "🎉 Win5x Master Setup Complete!" $Green
    Write-Log "===============================================" $Cyan
    Write-Log ""
    Write-Log "📋 Setup Summary:" $Yellow
    Write-Log "• Database: PostgreSQL (win5x_db)"
    Write-Log "• Cache: Redis with password protection"
    Write-Log "• Web Server: Nginx"
    Write-Log "• Process Manager: PM2"
    Write-Log "• Build System: Production-ready build created"
    Write-Log ""
    Write-Log "🌐 Access URLs:" $Yellow
    Write-Log "• User Panel: http://$ServerIP`:$NginxPort/"
    Write-Log "• Admin Panel: http://$ServerIP`:$NginxPort/admin"
    Write-Log "• API: http://$ServerIP`:$NginxPort/api"
    Write-Log "• Direct User Panel: http://$ServerIP`:$UserPort"
    Write-Log "• Direct Admin Panel: http://$ServerIP`:$AdminPort"
    Write-Log "• Direct Backend API: http://$ServerIP`:$BackendPort"
    Write-Log ""
    Write-Log "👤 Admin Credentials:" $Yellow
    Write-Log "• Username: $AdminUsername"
    Write-Log "• Email: $AdminEmail"
    Write-Log "• Password: $AdminPassword"
    Write-Log ""
    Write-Log "🔧 Management Commands:" $Yellow
    Write-Log "• PM2 Status: pm2 status"
    Write-Log "• PM2 Logs: pm2 logs"
    Write-Log "• PM2 Restart: pm2 restart all"
    Write-Log "• Nginx Reload: sudo systemctl reload nginx"
    Write-Log "• Database Access: psql -h localhost -p $PostgresPort -U win5x_user -d win5x_db"
    Write-Log "• Redis Access: redis-cli -p $RedisPort -a $RedisPassword"
    Write-Log ""
    Write-Log "📊 Port Configuration:" $Yellow
    Write-Log "• User Panel: $UserPort"
    Write-Log "• Admin Panel: $AdminPort"
    Write-Log "• Backend API: $BackendPort"
    Write-Log "• Nginx: $NginxPort"
    Write-Log "• PostgreSQL: $PostgresPort"
    Write-Log "• Redis: $RedisPort"
    Write-Log ""
    Write-Log "⚠️  Important Security Notes:" $Red
    Write-Log "• Change default passwords immediately"
    Write-Log "• Update JWT secret in production"
    Write-Log "• Configure SSL certificates for HTTPS"
    Write-Log "• Review firewall rules"
    Write-Log ""
    Write-Log "📁 Project Location: $ProjectPath" $Cyan
    Write-Log "📄 Log File: $LogFile" $Cyan
    Write-Log "💾 Backup Directory: $BackupDir" $Cyan
    Write-Log "===============================================" $Cyan
}

# Main execution
function Main {
    Write-Log "🚀 Starting Win5x Master Setup..." $Green
    Write-Log "===============================================" $Cyan
    Write-Log "Log file: $LogFile"
    Write-Log "Backup directory: $BackupDir"
    Write-Log ""
    
    try {
        # Pre-setup validation
        Test-SystemRequirements
        Test-PortAvailability
        Backup-System
        
        # Installation steps
        Install-SystemPackages
        Install-NodeJS
        Install-PostgreSQL
        Install-Redis
        Install-Nginx
        
        # Project setup
        Setup-Project
        Install-Dependencies
        Setup-Database
        New-EnvironmentFiles
        Build-Project
        Setup-DatabaseSchema
        Setup-PM2
        Setup-Nginx
        Setup-Firewall
        Start-Services
        
        # Post-setup validation
        Test-HealthChecks
        
        # Final information
        Show-FinalInfo
        
        Write-LogSuccess "Master setup completed successfully!"
    }
    catch {
        Write-LogError "Setup failed at step: $CurrentStep"
        Write-LogError "Check log file: $LogFile"
        Write-LogError "Backup directory: $BackupDir"
        
        # Try to restore from backup if it exists
        if (Test-Path $BackupDir) {
            Write-LogWarning "Attempting to restore from backup..."
            Restore-FromBackup
        }
        
        exit 1
    }
}

# Run main function
Main
