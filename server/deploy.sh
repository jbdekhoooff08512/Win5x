#!/bin/bash

# Win5x Server Deployment Script
# This script sets up the server for production deployment

set -e

echo "🚀 Starting Win5x Server Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the server directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: Please run this script from the server directory${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Installing backend dependencies...${NC}"
cd backend
npm install
echo -e "${GREEN}✅ Backend dependencies installed${NC}"

echo -e "${BLUE}🗄️ Setting up database...${NC}"
npx prisma generate
echo -e "${GREEN}✅ Database schema generated${NC}"

echo -e "${BLUE}🔧 Building backend...${NC}"
npm run build
echo -e "${GREEN}✅ Backend built successfully${NC}"

cd ..

echo -e "${BLUE}📋 Frontend builds are ready:${NC}"
echo -e "• Admin Panel: ${GREEN}admin/${NC}"
echo -e "• User Panel: ${GREEN}user/${NC}"
echo -e "• Common Package: ${GREEN}common/${NC}"

echo -e "${BLUE}⚙️ Configuration files:${NC}"
echo -e "• PM2 Config: ${GREEN}ecosystem.config.js${NC}"
echo -e "• Nginx Config: ${GREEN}nginx-win5x.conf${NC}"

echo ""
echo -e "${GREEN}🎉 Server deployment setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "1. Configure your database connection"
echo -e "2. Set up environment variables"
echo -e "3. Run database migrations: ${BLUE}cd backend && npx prisma migrate deploy${NC}"
echo -e "4. Start the server: ${BLUE}npm start${NC}"
echo -e "5. Configure Nginx with the provided config file"
echo ""
echo -e "${CYAN}===============================================${NC}"
