#!/bin/bash

# Win5x Server Clean Setup Script
# This script will clean everything and do a fresh setup

echo "🚀 Starting Win5x Server Clean Setup..."

# Server details
SERVER_IP="217.148.142.91"
SSH_PORT="6579"
SERVER_USER="root"
PROJECT_DIR="/var/www/win5x"

echo "📡 Connecting to server: $SERVER_USER@$SERVER_IP:$SSH_PORT"

# Function to execute commands on server
run_on_server() {
    ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP "$1"
}

# Function to copy files to server
copy_to_server() {
    scp -P $SSH_PORT -r "$1" $SERVER_USER@$SERVER_IP:"$2"
}

echo "🧹 Step 1: Stopping all PM2 processes"
run_on_server "pm2 stop all || true"
run_on_server "pm2 delete all || true"

echo "🗑️ Step 2: Cleaning old project directory"
run_on_server "rm -rf $PROJECT_DIR || true"
run_on_server "mkdir -p $PROJECT_DIR"

echo "📦 Step 3: Installing required packages"
run_on_server "apt update && apt install -y nodejs npm git nginx pm2"

echo "📁 Step 4: Uploading project files"
echo "   - Uploading main project files..."
copy_to_server "." "$PROJECT_DIR/"

echo "🔧 Step 5: Setting up project on server"
run_on_server "cd $PROJECT_DIR && npm install -g pnpm"
run_on_server "cd $PROJECT_DIR && pnpm install"

echo "🏗️ Step 6: Building all packages"
run_on_server "cd $PROJECT_DIR && pnpm run build"

echo "🗄️ Step 7: Setting up database"
run_on_server "cd $PROJECT_DIR/packages/backend && npx prisma generate"
run_on_server "cd $PROJECT_DIR/packages/backend && npx prisma db push"

echo "🌐 Step 8: Setting up Nginx configuration"
run_on_server "cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 80;
    server_name $SERVER_IP;

    # User Panel
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Admin Panel
    location /admin {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # API
    location /api {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Socket.IO
    location /socket.io {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Uploads
    location /uploads {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF"

echo "🔗 Step 9: Enabling Nginx site"
run_on_server "ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/"
run_on_server "rm -f /etc/nginx/sites-enabled/default"
run_on_server "nginx -t && systemctl reload nginx"

echo "🚀 Step 10: Starting applications with PM2"
run_on_server "cd $PROJECT_DIR && pm2 start ecosystem.config.js"

echo "💾 Step 11: Saving PM2 configuration"
run_on_server "pm2 save"
run_on_server "pm2 startup"

echo "🔍 Step 12: Checking application status"
run_on_server "pm2 status"

echo "📊 Step 13: Setting up log rotation"
run_on_server "cat > /etc/logrotate.d/win5x << 'EOF'
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
EOF"

echo "🔥 Step 14: Setting up firewall"
run_on_server "ufw allow 22/tcp"
run_on_server "ufw allow 80/tcp"
run_on_server "ufw allow 443/tcp"
run_on_server "ufw allow 8080:8082/tcp"
run_on_server "ufw --force enable"

echo "✅ Setup Complete!"
echo ""
echo "🌐 Access URLs:"
echo "   User Panel: http://$SERVER_IP"
echo "   Admin Panel: http://$SERVER_IP/admin"
echo "   Backend API: http://$SERVER_IP/api"
echo ""
echo "📱 Direct Port Access:"
echo "   User Panel: http://$SERVER_IP:8080"
echo "   Admin Panel: http://$SERVER_IP:8081"
echo "   Backend API: http://$SERVER_IP:8082"
echo ""
echo "🔧 Management Commands:"
echo "   PM2 Status: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 status'"
echo "   PM2 Logs: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 logs'"
echo "   Restart All: ssh -p $SSH_PORT $SERVER_USER@$SERVER_IP 'pm2 restart all'"
echo ""
echo "🎉 Server is ready!"
