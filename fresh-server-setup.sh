#!/bin/bash

# Fresh Server Setup Script for Win5x
# Run this on server: ssh -p 6579 root@217.148.142.91

echo "🚀 Starting Fresh Win5x Server Setup..."

# 1. Navigate to project directory
cd /var/www/win5x

# 2. Stop all PM2 processes
echo "📦 Stopping PM2 processes..."
pm2 stop all
pm2 delete all

# 3. Remove old files (keep only .git)
echo "🗑️ Cleaning old files..."
find . -maxdepth 1 -type f -delete
find . -maxdepth 1 -type d ! -name '.git' ! -name '.' -exec rm -rf {} +

# 4. Pull latest code from git
echo "📥 Pulling latest code..."
git pull origin main

# 5. Install dependencies
echo "📦 Installing dependencies..."
pnpm install

# 6. Build all packages
echo "🔨 Building packages..."
pnpm run build

# 7. Setup environment (if needed)
echo "⚙️ Setting up environment..."
# Copy .env files if they exist
if [ -f .env.example ]; then
    cp .env.example .env
fi

# 8. Database setup
echo "🗄️ Setting up database..."
cd packages/backend
pnpm run db:generate
pnpm run db:migrate

# 9. Start services with PM2
echo "🚀 Starting services..."
cd /var/www/win5x
pm2 start ecosystem.config.js

# 10. Save PM2 configuration
pm2 save
pm2 startup

echo "✅ Fresh setup completed!"
echo "🌐 Access URLs:"
echo "   Backend API: http://217.148.142.91:8082"
echo "   Admin Panel: http://217.148.142.91:8081"
echo "   User Panel: http://217.148.142.91:8080"

# 11. Show PM2 status
pm2 status
