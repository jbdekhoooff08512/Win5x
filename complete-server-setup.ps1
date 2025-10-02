# Win5x Complete Server Setup Script
# This script sets up everything needed for the Win5x application after OS reinstallation

param(
    [string]$DatabasePassword = "Win5xDB@2024",
    [string]$AdminUsername = "admin",
    [string]$AdminEmail = "admin@win5x.com",
    [string]$AdminPassword = "Admin@123",
    [string]$JwtSecret = "8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4",
    [string]$RedisPassword = "Redis@2024",
    [string]$ProjectPath = "/var/www/kart",
    [string]$ServerIP = "217.148.142.91",
    [int]$UserPort = 8080,
    [int]$AdminPort = 8081,
    [int]$BackendPort = 8082,
    [int]$RedisPort = 6379,
    [int]$PostgresPort = 5432,
    [int]$NginxPort = 80
)

Write-Host "🚀 Starting Win5x Complete Server Setup..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Function to run command with error handling
function Invoke-SafeCommand($command, $description) {
    Write-Host "📋 $description" -ForegroundColor Yellow
    try {
        Invoke-Expression $command
        Write-Host "✅ $description - Success" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ $description - Failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Update system packages
Write-Host "🔄 Updating system packages..." -ForegroundColor Blue
Invoke-SafeCommand "sudo apt update && sudo apt upgrade -y" "System update"

# Install essential packages
Write-Host "📦 Installing essential packages..." -ForegroundColor Blue
$essentialPackages = @(
    "curl", "wget", "git", "unzip", "software-properties-common",
    "apt-transport-https", "ca-certificates", "gnupg", "lsb-release"
)
Invoke-SafeCommand "sudo apt install -y $($essentialPackages -join ' ')" "Essential packages installation"

# Install Node.js 18.x
Write-Host "📦 Installing Node.js 18.x..." -ForegroundColor Blue
if (-not (Test-Command "node")) {
    Invoke-SafeCommand "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
    Invoke-SafeCommand "sudo apt install -y nodejs" "Node.js installation"
}

# Install pnpm
Write-Host "📦 Installing pnpm..." -ForegroundColor Blue
if (-not (Test-Command "pnpm")) {
    Invoke-SafeCommand "npm install -g pnpm@8.15.0" "pnpm installation"
}

# Install PM2
Write-Host "📦 Installing PM2..." -ForegroundColor Blue
if (-not (Test-Command "pm2")) {
    Invoke-SafeCommand "npm install -g pm2" "PM2 installation"
}

# Install PostgreSQL
Write-Host "📦 Installing PostgreSQL..." -ForegroundColor Blue
if (-not (Test-Command "psql")) {
    Invoke-SafeCommand "sudo apt install -y postgresql postgresql-contrib" "PostgreSQL installation"
    Invoke-SafeCommand "sudo systemctl start postgresql" "PostgreSQL service start"
    Invoke-SafeCommand "sudo systemctl enable postgresql" "PostgreSQL service enable"
}

# Install Redis
Write-Host "📦 Installing Redis..." -ForegroundColor Blue
if (-not (Test-Command "redis-server")) {
    Invoke-SafeCommand "sudo apt install -y redis-server" "Redis installation"
    Invoke-SafeCommand "sudo systemctl start redis-server" "Redis service start"
    Invoke-SafeCommand "sudo systemctl enable redis-server" "Redis service enable"
}

# Install Nginx
Write-Host "📦 Installing Nginx..." -ForegroundColor Blue
if (-not (Test-Command "nginx")) {
    Invoke-SafeCommand "sudo apt install -y nginx" "Nginx installation"
    Invoke-SafeCommand "sudo systemctl start nginx" "Nginx service start"
    Invoke-SafeCommand "sudo systemctl enable nginx" "Nginx service enable"
}

# Install serve for static file serving
Write-Host "📦 Installing serve..." -ForegroundColor Blue
Invoke-SafeCommand "npm install -g serve" "Serve installation"

# Create project directory
Write-Host "📁 Creating project directory..." -ForegroundColor Blue
Invoke-SafeCommand "sudo mkdir -p $ProjectPath" "Project directory creation"
Invoke-SafeCommand "sudo chown -R `$USER:`$USER $ProjectPath" "Project directory ownership"

# Clone repository (assuming you have the repo URL)
Write-Host "📥 Cloning repository..." -ForegroundColor Blue
if (-not (Test-Path "$ProjectPath/.git")) {
    Write-Host "Please provide your Git repository URL:" -ForegroundColor Yellow
    $repoUrl = Read-Host "Repository URL"
    Invoke-SafeCommand "git clone $repoUrl $ProjectPath" "Repository cloning"
}

# Navigate to project directory
Set-Location $ProjectPath

# Install dependencies
Write-Host "📦 Installing project dependencies..." -ForegroundColor Blue
Invoke-SafeCommand "pnpm install" "Project dependencies installation"

# Setup PostgreSQL database
Write-Host "🗄️ Setting up PostgreSQL database..." -ForegroundColor Blue
$dbName = "win5x_db"
$dbUser = "win5x_user"

# Create database and user
Invoke-SafeCommand "sudo -u postgres psql -c `"CREATE DATABASE $dbName;`"" "Database creation"
Invoke-SafeCommand "sudo -u postgres psql -c `"CREATE USER $dbUser WITH PASSWORD '$DatabasePassword';`"" "Database user creation"
Invoke-SafeCommand "sudo -u postgres psql -c `"GRANT ALL PRIVILEGES ON DATABASE $dbName TO $dbUser;`"" "Database privileges"

# Configure Redis
Write-Host "🔧 Configuring Redis..." -ForegroundColor Blue
$redisConfig = @"
# Redis configuration for Win5x
port $RedisPort
bind 127.0.0.1
requirepass $RedisPassword
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
"@

$redisConfig | Out-File -FilePath "/tmp/redis-win5x.conf" -Encoding UTF8
Invoke-SafeCommand "sudo cp /tmp/redis-win5x.conf /etc/redis/redis-win5x.conf" "Redis config copy"
Invoke-SafeCommand "sudo systemctl restart redis-server" "Redis service restart"

# Create environment files
Write-Host "🔧 Creating environment files..." -ForegroundColor Blue

# Backend .env
$backendEnv = @"
# Database
DATABASE_URL="postgresql://$dbUser`:$DatabasePassword`@localhost:$PostgresPort/$dbName"

# JWT
JWT_SECRET="$JwtSecret"
JWT_EXPIRES_IN="24h"

# Redis
REDIS_URL="redis://:$RedisPassword`@localhost:$RedisPort"

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

# Build the project
Write-Host "🔨 Building the project..." -ForegroundColor Blue
Invoke-SafeCommand "pnpm run build" "Project build"

# Setup database schema
Write-Host "🗄️ Setting up database schema..." -ForegroundColor Blue
Set-Location "packages/backend"
Invoke-SafeCommand "pnpm run db:generate" "Prisma client generation"
Invoke-SafeCommand "pnpm run db:migrate" "Database migration"
Set-Location "../.."

# Create admin user
Write-Host "👤 Creating admin user..." -ForegroundColor Blue
Set-Location "packages/backend"
$env:ADMIN_USERNAME = $AdminUsername
$env:ADMIN_EMAIL = $AdminEmail
$env:ADMIN_PASSWORD = $AdminPassword
Invoke-SafeCommand "pnpm run create-admin" "Admin user creation"
Set-Location "../.."

# Create logs directory
Write-Host "📁 Creating logs directory..." -ForegroundColor Blue
Invoke-SafeCommand "mkdir -p logs" "Logs directory creation"

# Setup PM2 ecosystem
Write-Host "🔧 Setting up PM2 ecosystem..." -ForegroundColor Blue
$ecosystemConfig = @"
module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/dist/server.js',
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

# Setup Nginx configuration
Write-Host "🔧 Setting up Nginx configuration..." -ForegroundColor Blue
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
Invoke-SafeCommand "sudo cp /tmp/win5x-nginx.conf /etc/nginx/sites-available/win5x" "Nginx config copy"
Invoke-SafeCommand "sudo ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/" "Nginx site enable"
Invoke-SafeCommand "sudo rm -f /etc/nginx/sites-enabled/default" "Default Nginx site removal"
Invoke-SafeCommand "sudo nginx -t" "Nginx configuration test"
Invoke-SafeCommand "sudo systemctl reload nginx" "Nginx reload"

# Start PM2 applications
Write-Host "🚀 Starting PM2 applications..." -ForegroundColor Blue
Invoke-SafeCommand "pm2 start ecosystem.config.js" "PM2 applications start"
Invoke-SafeCommand "pm2 save" "PM2 configuration save"
Invoke-SafeCommand "pm2 startup" "PM2 startup configuration"

# Setup firewall
Write-Host "🔥 Configuring firewall..." -ForegroundColor Blue
Invoke-SafeCommand "sudo ufw allow 22" "SSH firewall rule"
Invoke-SafeCommand "sudo ufw allow $NginxPort" "HTTP firewall rule"
Invoke-SafeCommand "sudo ufw allow 443" "HTTPS firewall rule"
Invoke-SafeCommand "sudo ufw allow $UserPort" "User panel firewall rule"
Invoke-SafeCommand "sudo ufw allow $AdminPort" "Admin panel firewall rule"
Invoke-SafeCommand "sudo ufw allow $BackendPort" "Backend API firewall rule"
Invoke-SafeCommand "sudo ufw --force enable" "Firewall enable"

# Create systemd service for PM2
Write-Host "🔧 Creating PM2 systemd service..." -ForegroundColor Blue
$pm2Service = @"
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=notify
User=`$USER
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PM2_HOME=/home/`$USER/.pm2
ExecStart=/usr/local/bin/pm2-runtime start ecosystem.config.js --env production
ExecReload=/usr/local/bin/pm2 reload ecosystem.config.js --env production
ExecStop=/usr/local/bin/pm2 kill

[Install]
WantedBy=multi-user.target
"@

$pm2Service | Out-File -FilePath "/tmp/pm2-win5x.service" -Encoding UTF8
Invoke-SafeCommand "sudo cp /tmp/pm2-win5x.service /etc/systemd/system/pm2-win5x.service" "PM2 service copy"
Invoke-SafeCommand "sudo systemctl daemon-reload" "Systemd daemon reload"
Invoke-SafeCommand "sudo systemctl enable pm2-win5x.service" "PM2 service enable"

# Final status check
Write-Host "🔍 Performing final status check..." -ForegroundColor Blue
Write-Host "PostgreSQL Status:" -ForegroundColor Yellow
Invoke-SafeCommand "sudo systemctl status postgresql --no-pager" "PostgreSQL status check"

Write-Host "Redis Status:" -ForegroundColor Yellow
Invoke-SafeCommand "sudo systemctl status redis-server --no-pager" "Redis status check"

Write-Host "Nginx Status:" -ForegroundColor Yellow
Invoke-SafeCommand "sudo systemctl status nginx --no-pager" "Nginx status check"

Write-Host "PM2 Status:" -ForegroundColor Yellow
Invoke-SafeCommand "pm2 status" "PM2 status check"

# Display final information
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "🎉 Win5x Server Setup Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Setup Summary:" -ForegroundColor Yellow
Write-Host "• Database: PostgreSQL (win5x_db)" -ForegroundColor White
Write-Host "• Cache: Redis with password protection" -ForegroundColor White
Write-Host "• Web Server: Nginx" -ForegroundColor White
Write-Host "• Process Manager: PM2" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Yellow
Write-Host "• User Panel: http://$ServerIP`:$NginxPort/" -ForegroundColor White
Write-Host "• Admin Panel: http://$ServerIP`:$NginxPort/admin" -ForegroundColor White
Write-Host "• API: http://$ServerIP`:$NginxPort/api" -ForegroundColor White
Write-Host "• Direct User Panel: http://$ServerIP`:$UserPort" -ForegroundColor White
Write-Host "• Direct Admin Panel: http://$ServerIP`:$AdminPort" -ForegroundColor White
Write-Host "• Direct Backend API: http://$ServerIP`:$BackendPort" -ForegroundColor White
Write-Host ""
Write-Host "👤 Admin Credentials:" -ForegroundColor Yellow
Write-Host "• Username: $AdminUsername" -ForegroundColor White
Write-Host "• Email: $AdminEmail" -ForegroundColor White
Write-Host "• Password: $AdminPassword" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Yellow
Write-Host "• PM2 Status: pm2 status" -ForegroundColor White
Write-Host "• PM2 Logs: pm2 logs" -ForegroundColor White
Write-Host "• PM2 Restart: pm2 restart all" -ForegroundColor White
Write-Host "• Nginx Reload: sudo systemctl reload nginx" -ForegroundColor White
Write-Host "• Database Access: psql -h localhost -p $PostgresPort -U $dbUser -d $dbName" -ForegroundColor White
Write-Host "• Redis Access: redis-cli -p $RedisPort -a $RedisPassword" -ForegroundColor White
Write-Host ""
Write-Host "📊 Port Configuration:" -ForegroundColor Yellow
Write-Host "• User Panel: $UserPort" -ForegroundColor White
Write-Host "• Admin Panel: $AdminPort" -ForegroundColor White
Write-Host "• Backend API: $BackendPort" -ForegroundColor White
Write-Host "• Nginx: $NginxPort" -ForegroundColor White
Write-Host "• PostgreSQL: $PostgresPort" -ForegroundColor White
Write-Host "• Redis: $RedisPort" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important Security Notes:" -ForegroundColor Red
Write-Host "• Change default passwords immediately" -ForegroundColor White
Write-Host "• Update JWT secret in production" -ForegroundColor White
Write-Host "• Configure SSL certificates for HTTPS" -ForegroundColor White
Write-Host "• Review firewall rules" -ForegroundColor White
Write-Host ""
Write-Host "📁 Project Location: $ProjectPath" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
