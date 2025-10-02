# Win5x Server Clean Setup Script (PowerShell)
# This script will clean everything and do a fresh setup

Write-Host "🚀 Starting Win5x Server Clean Setup..." -ForegroundColor Green

# Server details
$SERVER_IP = "217.148.142.91"
$SSH_PORT = "6579"
$SERVER_USER = "root"
$PROJECT_DIR = "/var/www/win5x"

Write-Host "📡 Connecting to server: $SERVER_USER@$SERVER_IP`:$SSH_PORT" -ForegroundColor Cyan

# Function to execute commands on server
function Invoke-ServerCommand {
    param([string]$Command)
    ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP $Command
}

# Function to copy files to server
function Copy-ToServer {
    param([string]$Source, [string]$Destination)
    scp -P $SSH_PORT -r $Source $SERVER_USER@$SERVER_IP`:$Destination
}

Write-Host "🧹 Step 1: Stopping all PM2 processes" -ForegroundColor Yellow
Invoke-ServerCommand "pm2 stop all || true"
Invoke-ServerCommand "pm2 delete all || true"

Write-Host "🗑️ Step 2: Cleaning old project directory" -ForegroundColor Yellow
Invoke-ServerCommand "rm -rf $PROJECT_DIR || true"
Invoke-ServerCommand "mkdir -p $PROJECT_DIR"

Write-Host "📦 Step 3: Installing required packages" -ForegroundColor Yellow
Invoke-ServerCommand "apt update && apt install -y nodejs npm git nginx pm2"

Write-Host "📁 Step 4: Uploading project files" -ForegroundColor Yellow
Write-Host "   - Uploading main project files..." -ForegroundColor Gray
Copy-ToServer "." $PROJECT_DIR

Write-Host "🔧 Step 5: Setting up project on server" -ForegroundColor Yellow
Invoke-ServerCommand "cd $PROJECT_DIR && npm install -g pnpm"
Invoke-ServerCommand "cd $PROJECT_DIR && pnpm install"

Write-Host "🏗️ Step 6: Building all packages" -ForegroundColor Yellow
Invoke-ServerCommand "cd $PROJECT_DIR && pnpm run build"

Write-Host "🗄️ Step 7: Setting up database" -ForegroundColor Yellow
Invoke-ServerCommand "cd $PROJECT_DIR/packages/backend && npx prisma generate"
Invoke-ServerCommand "cd $PROJECT_DIR/packages/backend && npx prisma db push"

Write-Host "🌐 Step 8: Setting up Nginx configuration" -ForegroundColor Yellow
$nginxConfig = @"
server {
    listen 80;
    server_name $SERVER_IP;

    # User Panel
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # Admin Panel
    location /admin {
        proxy_pass http://127.0.0.1:8081;
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
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # Socket.IO
    location /socket.io {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }

    # Uploads
    location /uploads {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
}
"@

Invoke-ServerCommand "cat > /etc/nginx/sites-available/win5x << 'EOF'
$nginxConfig
EOF"

Write-Host "🔗 Step 9: Enabling Nginx site" -ForegroundColor Yellow
Invoke-ServerCommand "ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/"
Invoke-ServerCommand "rm -f /etc/nginx/sites-enabled/default"
Invoke-ServerCommand "nginx -t && systemctl reload nginx"

Write-Host "🚀 Step 10: Starting applications with PM2" -ForegroundColor Yellow
Invoke-ServerCommand "cd $PROJECT_DIR && pm2 start ecosystem.config.js"

Write-Host "💾 Step 11: Saving PM2 configuration" -ForegroundColor Yellow
Invoke-ServerCommand "pm2 save"
Invoke-ServerCommand "pm2 startup"

Write-Host "🔍 Step 12: Checking application status" -ForegroundColor Yellow
Invoke-ServerCommand "pm2 status"

Write-Host "📊 Step 13: Setting up log rotation" -ForegroundColor Yellow
$logRotateConfig = @"
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        pm2 reloadLogs
    endscript
}
"@

Invoke-ServerCommand "cat > /etc/logrotate.d/win5x << 'EOF'
$logRotateConfig
EOF"

Write-Host "🔥 Step 14: Setting up firewall" -ForegroundColor Yellow
Invoke-ServerCommand "ufw allow 22/tcp"
Invoke-ServerCommand "ufw allow 80/tcp"
Invoke-ServerCommand "ufw allow 443/tcp"
Invoke-ServerCommand "ufw allow 8080:8082/tcp"
Invoke-ServerCommand "ufw --force enable"

Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "   User Panel: http://$SERVER_IP" -ForegroundColor White
Write-Host "   Admin Panel: http://$SERVER_IP/admin" -ForegroundColor White
Write-Host "   Backend API: http://$SERVER_IP/api" -ForegroundColor White
Write-Host ""
Write-Host "📱 Direct Port Access:" -ForegroundColor Cyan
Write-Host "   User Panel: http://$SERVER_IP`:8080" -ForegroundColor White
Write-Host "   Admin Panel: http://$SERVER_IP`:8081" -ForegroundColor White
Write-Host "   Backend API: http://$SERVER_IP`:8082" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "   PM2 Status: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 status'" -ForegroundColor White
Write-Host "   PM2 Logs: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 logs'" -ForegroundColor White
Write-Host "   Restart All: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 restart all'" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Server is ready!" -ForegroundColor Green
