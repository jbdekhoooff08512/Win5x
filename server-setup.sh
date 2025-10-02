#!/bin/bash
# Win5x Server Setup Script
# Upload this to your server and run it

set -e

echo "================================"
echo "   Win5x Server Setup"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Update system
echo -e "${YELLOW}📦 Step 1: Updating system...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✅ System updated!${NC}"
echo ""

# Step 2: Install Node.js
echo -e "${YELLOW}📦 Step 2: Installing Node.js 18...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
node --version
echo -e "${GREEN}✅ Node.js installed!${NC}"
echo ""

# Step 3: Install PNPM
echo -e "${YELLOW}📦 Step 3: Installing PNPM...${NC}"
npm install -g pnpm
pnpm --version
echo -e "${GREEN}✅ PNPM installed!${NC}"
echo ""

# Step 4: Install PostgreSQL
echo -e "${YELLOW}📦 Step 4: Installing PostgreSQL...${NC}"
apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
echo -e "${GREEN}✅ PostgreSQL installed!${NC}"
echo ""

# Step 5: Create Database
echo -e "${YELLOW}📦 Step 5: Creating database...${NC}"
sudo -u postgres psql << 'EOF'
CREATE DATABASE win5x;
CREATE USER win5x_user WITH ENCRYPTED PASSWORD 'Win5xSecure2024!';
ALTER DATABASE win5x OWNER TO win5x_user;
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x_user;
\c win5x
GRANT ALL ON SCHEMA public TO win5x_user;
\q
EOF
echo -e "${GREEN}✅ Database created!${NC}"
echo ""

# Step 6: Install Redis
echo -e "${YELLOW}📦 Step 6: Installing Redis...${NC}"
apt install -y redis-server
systemctl start redis-server
systemctl enable redis-server
redis-cli ping
echo -e "${GREEN}✅ Redis installed!${NC}"
echo ""

# Step 7: Install PM2
echo -e "${YELLOW}📦 Step 7: Installing PM2...${NC}"
npm install -g pm2
pm2 --version
echo -e "${GREEN}✅ PM2 installed!${NC}"
echo ""

# Step 8: Install Nginx
echo -e "${YELLOW}📦 Step 8: Installing Nginx...${NC}"
apt install -y nginx
systemctl start nginx
systemctl enable nginx
echo -e "${GREEN}✅ Nginx installed!${NC}"
echo ""

# Step 9: Create deployment directory
echo -e "${YELLOW}📦 Step 9: Creating deployment directory...${NC}"
mkdir -p /var/www/win5x
cd /var/www/win5x
echo -e "${GREEN}✅ Directory created!${NC}"
echo ""

# Step 10: Create .env file
echo -e "${YELLOW}📦 Step 10: Creating .env file...${NC}"
mkdir -p /var/www/win5x/packages/backend
cat > /var/www/win5x/packages/backend/.env << 'EOF'
DATABASE_URL="postgresql://win5x_user:Win5xSecure2024!@localhost:5432/win5x"
REDIS_URL="redis://localhost:6379"
JWT_SECRET="xK9mP2nQ7wR4tY8uI3oL6jH5gF1dS0aZ9xC8vB7nM6qW5eR4tY3uI2oP1"
JWT_REFRESH_SECRET="bN4vC9xZ2sA5dF8gH1jK4lP7qW0eR3tY6uI9oM2nB5vC8xZ1aS4dF7gH"
NODE_ENV="production"
PORT=3001
CORS_ALLOWED_ORIGINS="http://217.148.142.91,http://217.148.142.91:8080"
BCRYPT_ROUNDS=12
EOF
echo -e "${GREEN}✅ .env file created!${NC}"
echo ""

# Step 11: Create PM2 ecosystem config
echo -e "${YELLOW}📦 Step 11: Creating PM2 config...${NC}"
cat > /var/www/win5x/ecosystem.config.js << 'EOF'
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
    },
    error_file: '/var/www/win5x/packages/backend/logs/error.log',
    out_file: '/var/www/win5x/packages/backend/logs/out.log'
  }]
};
EOF
echo -e "${GREEN}✅ PM2 config created!${NC}"
echo ""

# Step 12: Configure Nginx
echo -e "${YELLOW}📦 Step 12: Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 8080;
    server_name 217.148.142.91;

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket
    location /socket.io/ {
        proxy_pass http://localhost:3001/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # User Panel
    location / {
        root /var/www/win5x/packages/user/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    # Admin Panel
    location /admin/ {
        alias /var/www/win5x/packages/admin/dist/;
        try_files $uri $uri/ /admin/index.html;
        index index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
echo -e "${GREEN}✅ Nginx configured!${NC}"
echo ""

# Step 13: Configure firewall
echo -e "${YELLOW}📦 Step 13: Configuring firewall...${NC}"
ufw allow 6579/tcp  # SSH
ufw allow 8080/tcp  # Web
ufw allow 3001/tcp  # API
echo -e "${GREEN}✅ Firewall configured!${NC}"
echo ""

echo "================================"
echo -e "${GREEN}✅ Server Setup Complete!${NC}"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Upload your application files to /var/www/win5x"
echo "2. Run: cd /var/www/win5x && pnpm install --prod"
echo "3. Run: cd packages/backend && pnpm db:generate && pnpm db:migrate && pnpm db:seed"
echo "4. Run: cd /var/www/win5x && pm2 start ecosystem.config.js"
echo "5. Run: pm2 save && pm2 startup"
echo ""


