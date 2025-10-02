#!/bin/bash
# Complete Win5x Setup and Deployment Script
# This script handles everything after files are uploaded

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================"
echo "   Win5x Deployment"
echo "================================"
echo ""

# Move and extract uploaded files
if [ -f "/root/win5x-deploy.tar.gz" ]; then
    echo -e "${YELLOW}📦 Moving files...${NC}"
    mv /root/win5x-deploy.tar.gz /var/www/win5x/
fi

# Navigate to project directory
cd /var/www/win5x

# Extract uploaded files
if [ -f "win5x-deploy.tar.gz" ]; then
    echo -e "${YELLOW}📦 Extracting files...${NC}"
    tar -xzf win5x-deploy.tar.gz
    rm win5x-deploy.tar.gz
    echo -e "${GREEN}✅ Files extracted!${NC}"
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
pnpm install --prod
echo -e "${GREEN}✅ Dependencies installed!${NC}"

# Setup database
echo -e "${YELLOW}📦 Setting up database...${NC}"
cd packages/backend
pnpm db:generate
pnpm db:migrate
pnpm db:seed
cd ../..
echo -e "${GREEN}✅ Database setup complete!${NC}"

# Start application with PM2
echo -e "${YELLOW}🚀 Starting application...${NC}"
pm2 delete win5x-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
echo -e "${GREEN}✅ Application started!${NC}"

# Setup PM2 startup
echo -e "${YELLOW}📦 Configuring PM2 startup...${NC}"
pm2 startup systemd -u root --hp /root | tail -n 1 | bash
echo -e "${GREEN}✅ PM2 startup configured!${NC}"

echo ""
echo "================================"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "================================"
echo ""
echo "🌐 Your application is now running at:"
echo "   User Panel:  http://217.148.142.91:8080"
echo "   Admin Panel: http://217.148.142.91:8080/admin"
echo "   Backend API: http://217.148.142.91:3001"
echo ""
echo "Default Admin Credentials:"
echo "   Username: admin"
echo "   Password: Admin123!"
echo ""
echo "Useful commands:"
echo "   pm2 status          - Check application status"
echo "   pm2 logs            - View logs"
echo "   pm2 restart all     - Restart application"
echo ""

