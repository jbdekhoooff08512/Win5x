#!/bin/bash

# Win5x Complete Server Setup Script (Linux/Ubuntu)
# This script sets up everything needed for the Win5x application after OS reinstallation

# Default configuration
DATABASE_PASSWORD="${DATABASE_PASSWORD:-Win5xDB@2024}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@win5x.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@123}"
JWT_SECRET="${JWT_SECRET:-8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4}"
REDIS_PASSWORD="${REDIS_PASSWORD:-Redis@2024}"
PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"
SERVER_IP="${SERVER_IP:-0.0.0.0}"
USER_PORT="${USER_PORT:-8080}"
ADMIN_PORT="${ADMIN_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8082}"
REDIS_PORT="${REDIS_PORT:-6379}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
NGINX_PORT="${NGINX_PORT:-80}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Win5x Complete Server Setup...${NC}"
echo -e "${CYAN}===============================================${NC}"

# Function to run command with error handling
run_command() {
    local command="$1"
    local description="$2"
    
    echo -e "${YELLOW}📋 $description${NC}"
    if eval "$command"; then
        echo -e "${GREEN}✅ $description - Success${NC}"
    else
        echo -e "${RED}❌ $description - Failed${NC}"
        exit 1
    fi
}

# Update system packages
echo -e "${BLUE}🔄 Updating system packages...${NC}"
run_command "sudo apt update && sudo apt upgrade -y" "System update"

# Install essential packages
echo -e "${BLUE}📦 Installing essential packages...${NC}"
ESSENTIAL_PACKAGES="curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release"
run_command "sudo apt install -y $ESSENTIAL_PACKAGES" "Essential packages installation"

# Install Node.js 18.x
echo -e "${BLUE}📦 Installing Node.js 18.x...${NC}"
if ! command -v node &> /dev/null; then
    run_command "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
    run_command "sudo apt install -y nodejs" "Node.js installation"
fi

# Install pnpm
echo -e "${BLUE}📦 Installing pnpm...${NC}"
if ! command -v pnpm &> /dev/null; then
    run_command "npm install -g pnpm@8.15.0" "pnpm installation"
fi

# Install PM2
echo -e "${BLUE}📦 Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    run_command "npm install -g pm2" "PM2 installation"
fi

# Install PostgreSQL
echo -e "${BLUE}📦 Installing PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    run_command "sudo apt install -y postgresql postgresql-contrib" "PostgreSQL installation"
    run_command "sudo systemctl start postgresql" "PostgreSQL service start"
    run_command "sudo systemctl enable postgresql" "PostgreSQL service enable"
fi

# Install Redis
echo -e "${BLUE}📦 Installing Redis...${NC}"
if ! command -v redis-server &> /dev/null; then
    run_command "sudo apt install -y redis-server" "Redis installation"
    run_command "sudo systemctl start redis-server" "Redis service start"
    run_command "sudo systemctl enable redis-server" "Redis service enable"
fi

# Install Nginx
echo -e "${BLUE}📦 Installing Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    run_command "sudo apt install -y nginx" "Nginx installation"
    run_command "sudo systemctl start nginx" "Nginx service start"
    run_command "sudo systemctl enable nginx" "Nginx service enable"
fi

# Install serve for static file serving
echo -e "${BLUE}📦 Installing serve...${NC}"
run_command "npm install -g serve" "Serve installation"

# Create project directory
echo -e "${BLUE}📁 Creating project directory...${NC}"
run_command "sudo mkdir -p $PROJECT_PATH" "Project directory creation"
run_command "sudo chown -R $USER:$USER $PROJECT_PATH" "Project directory ownership"

# Clone repository (assuming you have the repo URL)
echo -e "${BLUE}📥 Cloning repository...${NC}"
if [ ! -d "$PROJECT_PATH/.git" ]; then
    echo -e "${YELLOW}Please provide your Git repository URL:${NC}"
    read -p "Repository URL: " REPO_URL
    run_command "git clone $REPO_URL $PROJECT_PATH" "Repository cloning"
fi

# Navigate to project directory
cd "$PROJECT_PATH"

# Install dependencies
echo -e "${BLUE}📦 Installing project dependencies...${NC}"
run_command "pnpm install" "Project dependencies installation"

# Setup PostgreSQL database
echo -e "${BLUE}🗄️ Setting up PostgreSQL database...${NC}"
DB_NAME="win5x_db"
DB_USER="win5x_user"

# Create database and user
run_command "sudo -u postgres psql -c \"CREATE DATABASE $DB_NAME;\"" "Database creation"
run_command "sudo -u postgres psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DATABASE_PASSWORD';\"" "Database user creation"
run_command "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;\"" "Database privileges"

# Configure Redis
echo -e "${BLUE}🔧 Configuring Redis...${NC}"
cat > /tmp/redis-win5x.conf << EOF
# Redis configuration for Win5x
port $REDIS_PORT
bind 127.0.0.1
requirepass $REDIS_PASSWORD
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF

run_command "sudo cp /tmp/redis-win5x.conf /etc/redis/redis-win5x.conf" "Redis config copy"
run_command "sudo systemctl restart redis-server" "Redis service restart"

# Create environment files
echo -e "${BLUE}🔧 Creating environment files...${NC}"

# Backend .env
cat > packages/backend/.env << EOF
# Database
DATABASE_URL="postgresql://$DB_USER:$DATABASE_PASSWORD@localhost:$POSTGRES_PORT/$DB_NAME"

# JWT
JWT_SECRET="$JWT_SECRET"
JWT_EXPIRES_IN="24h"

# Redis
REDIS_URL="redis://:$REDIS_PASSWORD@localhost:$REDIS_PORT"

# Server
PORT=$BACKEND_PORT
NODE_ENV=production

# Admin credentials
ADMIN_USERNAME="$ADMIN_USERNAME"
ADMIN_EMAIL="$ADMIN_EMAIL"
ADMIN_PASSWORD="$ADMIN_PASSWORD"

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
EOF

# Admin .env
cat > packages/admin/.env << EOF
VITE_API_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_SOCKET_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
EOF

# User .env
cat > packages/user/.env << EOF
VITE_API_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_SOCKET_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
EOF

# Build the project
echo -e "${BLUE}🔨 Building the project...${NC}"
run_command "pnpm run build" "Project build"

# Setup database schema
echo -e "${BLUE}🗄️ Setting up database schema...${NC}"
cd packages/backend
run_command "pnpm run db:generate" "Prisma client generation"
run_command "pnpm run db:migrate" "Database migration"
cd ../..

# Create admin user
echo -e "${BLUE}👤 Creating admin user...${NC}"
cd packages/backend
export ADMIN_USERNAME="$ADMIN_USERNAME"
export ADMIN_EMAIL="$ADMIN_EMAIL"
export ADMIN_PASSWORD="$ADMIN_PASSWORD"
run_command "pnpm run create-admin" "Admin user creation"
cd ../..

# Create logs directory
echo -e "${BLUE}📁 Creating logs directory...${NC}"
run_command "mkdir -p logs" "Logs directory creation"

# Setup PM2 ecosystem
echo -e "${BLUE}🔧 Setting up PM2 ecosystem...${NC}"
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/dist/server.js',
      cwd: '$PROJECT_PATH',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: $BACKEND_PORT
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
      args: '-s packages/admin/dist -p $ADMIN_PORT',
      cwd: '$PROJECT_PATH',
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
      args: '-s packages/user/dist -p $USER_PORT',
      cwd: '$PROJECT_PATH',
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
EOF

# Setup Nginx configuration
echo -e "${BLUE}🔧 Setting up Nginx configuration...${NC}"
cat > /tmp/win5x-nginx.conf << EOF
server {
    listen $NGINX_PORT;
    server_name _;

    # User panel
    location / {
        proxy_pass http://localhost:$USER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Admin panel
    location /admin {
        proxy_pass http://localhost:$ADMIN_PORT;
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
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Socket.io
    location /socket.io/ {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

run_command "sudo cp /tmp/win5x-nginx.conf /etc/nginx/sites-available/win5x" "Nginx config copy"
run_command "sudo ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/" "Nginx site enable"
run_command "sudo rm -f /etc/nginx/sites-enabled/default" "Default Nginx site removal"
run_command "sudo nginx -t" "Nginx configuration test"
run_command "sudo systemctl reload nginx" "Nginx reload"

# Start PM2 applications
echo -e "${BLUE}🚀 Starting PM2 applications...${NC}"
run_command "pm2 start ecosystem.config.js" "PM2 applications start"
run_command "pm2 save" "PM2 configuration save"
run_command "pm2 startup" "PM2 startup configuration"

# Setup firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
run_command "sudo ufw allow 22" "SSH firewall rule"
run_command "sudo ufw allow $NGINX_PORT" "HTTP firewall rule"
run_command "sudo ufw allow 443" "HTTPS firewall rule"
run_command "sudo ufw allow $USER_PORT" "User panel firewall rule"
run_command "sudo ufw allow $ADMIN_PORT" "Admin panel firewall rule"
run_command "sudo ufw allow $BACKEND_PORT" "Backend API firewall rule"
run_command "sudo ufw --force enable" "Firewall enable"

# Create systemd service for PM2
echo -e "${BLUE}🔧 Creating PM2 systemd service...${NC}"
cat > /tmp/pm2-win5x.service << EOF
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=notify
User=$USER
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PM2_HOME=/home/$USER/.pm2
ExecStart=/usr/local/bin/pm2-runtime start ecosystem.config.js --env production
ExecReload=/usr/local/bin/pm2 reload ecosystem.config.js --env production
ExecStop=/usr/local/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOF

run_command "sudo cp /tmp/pm2-win5x.service /etc/systemd/system/pm2-win5x.service" "PM2 service copy"
run_command "sudo systemctl daemon-reload" "Systemd daemon reload"
run_command "sudo systemctl enable pm2-win5x.service" "PM2 service enable"

# Final status check
echo -e "${BLUE}🔍 Performing final status check...${NC}"
echo -e "${YELLOW}PostgreSQL Status:${NC}"
sudo systemctl status postgresql --no-pager

echo -e "${YELLOW}Redis Status:${NC}"
sudo systemctl status redis-server --no-pager

echo -e "${YELLOW}Nginx Status:${NC}"
sudo systemctl status nginx --no-pager

echo -e "${YELLOW}PM2 Status:${NC}"
pm2 status

# Display final information
echo -e "${CYAN}===============================================${NC}"
echo -e "${GREEN}🎉 Win5x Server Setup Complete!${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo -e "${YELLOW}📋 Setup Summary:${NC}"
echo -e "• Database: PostgreSQL (win5x_db)${NC}"
echo -e "• Cache: Redis with password protection${NC}"
echo -e "• Web Server: Nginx${NC}"
echo -e "• Process Manager: PM2${NC}"
echo ""
echo -e "${YELLOW}🌐 Access URLs:${NC}"
echo -e "• User Panel: http://$SERVER_IP:$NGINX_PORT/${NC}"
echo -e "• Admin Panel: http://$SERVER_IP:$NGINX_PORT/admin${NC}"
echo -e "• API: http://$SERVER_IP:$NGINX_PORT/api${NC}"
echo -e "• Direct User Panel: http://$SERVER_IP:$USER_PORT${NC}"
echo -e "• Direct Admin Panel: http://$SERVER_IP:$ADMIN_PORT${NC}"
echo -e "• Direct Backend API: http://$SERVER_IP:$BACKEND_PORT${NC}"
echo ""
echo -e "${YELLOW}👤 Admin Credentials:${NC}"
echo -e "• Username: $ADMIN_USERNAME${NC}"
echo -e "• Email: $ADMIN_EMAIL${NC}"
echo -e "• Password: $ADMIN_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo -e "• PM2 Status: pm2 status${NC}"
echo -e "• PM2 Logs: pm2 logs${NC}"
echo -e "• PM2 Restart: pm2 restart all${NC}"
echo -e "• Nginx Reload: sudo systemctl reload nginx${NC}"
echo -e "• Database Access: psql -h localhost -p $POSTGRES_PORT -U $DB_USER -d $DB_NAME${NC}"
echo -e "• Redis Access: redis-cli -p $REDIS_PORT -a $REDIS_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}📊 Port Configuration:${NC}"
echo -e "• User Panel: $USER_PORT${NC}"
echo -e "• Admin Panel: $ADMIN_PORT${NC}"
echo -e "• Backend API: $BACKEND_PORT${NC}"
echo -e "• Nginx: $NGINX_PORT${NC}"
echo -e "• PostgreSQL: $POSTGRES_PORT${NC}"
echo -e "• Redis: $REDIS_PORT${NC}"
echo ""
echo -e "${RED}⚠️  Important Security Notes:${NC}"
echo -e "• Change default passwords immediately${NC}"
echo -e "• Update JWT secret in production${NC}"
echo -e "• Configure SSL certificates for HTTPS${NC}"
echo -e "• Review firewall rules${NC}"
echo ""
echo -e "${CYAN}📁 Project Location: $PROJECT_PATH${NC}"
echo -e "${CYAN}===============================================${NC}"
