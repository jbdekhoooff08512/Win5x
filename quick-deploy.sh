#!/bin/bash
# Win5x Quick Deployment Script
# Run this on your server: bash quick-deploy.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================"
echo "   Win5x Quick Deploy"
echo "================================"
echo ""

# Fix dpkg issue first
echo -e "${YELLOW}🔧 Fixing dpkg issue...${NC}"
dpkg --configure -a || true
apt-get install -f -y || true

# Update package list only (no upgrade)
echo -e "${YELLOW}📦 Updating package list...${NC}"
apt update

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Node.js 18...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi
echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"

# Check if PNPM is installed
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}📦 Installing PNPM...${NC}"
    npm install -g pnpm
fi
echo -e "${GREEN}✅ PNPM: $(pnpm --version)${NC}"

# Install PostgreSQL if not present
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}📦 Installing PostgreSQL...${NC}"
    apt install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
fi
echo -e "${GREEN}✅ PostgreSQL installed${NC}"

# Install Redis if not present
if ! command -v redis-cli &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Redis...${NC}"
    apt install -y redis-server
    systemctl start redis-server
    systemctl enable redis-server
fi
echo -e "${GREEN}✅ Redis installed${NC}"

# Install PM2 if not present
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 Installing PM2...${NC}"
    npm install -g pm2
fi
echo -e "${GREEN}✅ PM2 installed${NC}"

# Install Nginx if not present
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Nginx...${NC}"
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
fi
echo -e "${GREEN}✅ Nginx installed${NC}"

# Create database if it doesn't exist
echo -e "${YELLOW}📦 Setting up database...${NC}"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'win5x'" | grep -q 1 || \
sudo -u postgres psql << 'EOF'
CREATE DATABASE win5x;
CREATE USER win5x_user WITH ENCRYPTED PASSWORD 'Win5xSecure2024!';
ALTER DATABASE win5x OWNER TO win5x_user;
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x_user;
\c win5x
GRANT ALL ON SCHEMA public TO win5x_user;
EOF
echo -e "${GREEN}✅ Database ready${NC}"

# Create deployment directory
echo -e "${YELLOW}📦 Creating deployment directory...${NC}"
mkdir -p /var/www/win5x
cd /var/www/win5x

# Create .env file
echo -e "${YELLOW}📦 Creating configuration...${NC}"
mkdir -p packages/backend
cat > packages/backend/.env << 'EOF'
DATABASE_URL="postgresql://win5x_user:Win5xSecure2024!@localhost:5432/win5x"
REDIS_URL="redis://localhost:6379"
JWT_SECRET="xK9mP2nQ7wR4tY8uI3oL6jH5gF1dS0aZ9xC8vB7nM6qW5eR4tY3uI2oP1"
JWT_REFRESH_SECRET="bN4vC9xZ2sA5dF8gH1jK4lP7qW0eR3tY6uI9oM2nB5vC8xZ1aS4dF7gH"
NODE_ENV="production"
PORT=3001
CORS_ALLOWED_ORIGINS="http://217.148.142.91,http://217.148.142.91:8080"
BCRYPT_ROUNDS=12
EOF

# Create PM2 ecosystem config
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'win5x-backend',
    cwd: '/var/www/win5x/packages/backend',
    script: 'dist/server.js',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    }
  }]
};
EOF

# Create Nginx configuration
cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 8080;
    server_name 217.148.142.91;

    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /socket.io/ {
        proxy_pass http://localhost:3001/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        root /var/www/win5x/packages/user/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    location /admin/ {
        alias /var/www/win5x/packages/admin/dist/;
        try_files $uri $uri/ /admin/index.html;
        index index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo -e "${GREEN}✅ Configuration complete${NC}"

# Configure firewall
echo -e "${YELLOW}🔒 Configuring firewall...${NC}"
ufw allow 6579/tcp 2>/dev/null || true
ufw allow 8080/tcp 2>/dev/null || true
ufw allow 3001/tcp 2>/dev/null || true

echo ""
echo "================================"
echo -e "${GREEN}✅ Server Setup Complete!${NC}"
echo "================================"
echo ""
echo "Next: Upload your application files and run setup-and-deploy.sh"
echo ""


