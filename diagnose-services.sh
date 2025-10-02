#!/bin/bash

# Win5x Service Diagnostic Script
# This script will diagnose and fix 502 Bad Gateway issues

echo "========================================="
echo "    Win5x Service Diagnostic Script"
echo "========================================="
echo

cd /var/www/kart

echo "🔍 Step 1: Checking PM2 process status..."
pm2 status
echo

echo "🔍 Step 2: Checking if services are listening on correct ports..."
echo "Checking port 3001 (Backend):"
netstat -tlnp | grep :3001 || echo "❌ Backend not listening on port 3001"

echo "Checking port 8080 (User Frontend):"
netstat -tlnp | grep :8080 || echo "❌ User frontend not listening on port 8080"

echo "Checking port 8081 (Admin Frontend):"
netstat -tlnp | grep :8081 || echo "❌ Admin frontend not listening on port 8081"
echo

echo "🔍 Step 3: Checking PM2 logs for errors..."
echo "Backend logs:"
pm2 logs win5x-backend --lines 10 2>/dev/null || echo "❌ Backend process not found"

echo "Admin logs:"
pm2 logs win5x-admin --lines 10 2>/dev/null || echo "❌ Admin process not found"

echo "User logs:"
pm2 logs win5x-user --lines 10 2>/dev/null || echo "❌ User process not found"
echo

echo "🔍 Step 4: Checking if build files exist..."
if [ -d "packages/backend/dist" ]; then
    echo "✅ Backend dist directory exists"
    ls -la packages/backend/dist/ | head -5
else
    echo "❌ Backend dist directory missing - need to build"
fi

if [ -d "packages/admin/dist" ]; then
    echo "✅ Admin dist directory exists"
    ls -la packages/admin/dist/ | head -5
else
    echo "❌ Admin dist directory missing - need to build"
fi

if [ -d "packages/user/dist" ]; then
    echo "✅ User dist directory exists"
    ls -la packages/user/dist/ | head -5
else
    echo "❌ User dist directory missing - need to build"
fi
echo

echo "🔍 Step 5: Checking Nginx configuration..."
nginx -t
echo

echo "🔍 Step 6: Checking Nginx error logs..."
tail -10 /var/log/nginx/error.log 2>/dev/null || echo "No nginx error log found"
echo

echo "🔧 Step 7: Attempting to fix issues..."

# Stop all PM2 processes
echo "Stopping all PM2 processes..."
pm2 delete all 2>/dev/null || true

# Rebuild if needed
if [ ! -d "packages/backend/dist" ] || [ ! -d "packages/admin/dist" ] || [ ! -d "packages/user/dist" ]; then
    echo "🔨 Rebuilding project..."
    pnpm run build
fi

# Install serve globally if not installed
if ! command -v serve &> /dev/null; then
    echo "📦 Installing serve globally..."
    npm install -g serve
fi

# Create logs directory
mkdir -p logs

# Start PM2 processes
echo "🚀 Starting PM2 processes..."
pm2 start ecosystem.config.js
pm2 save

echo "✅ PM2 processes started!"
echo

echo "🔍 Step 8: Final status check..."
sleep 3
pm2 status
echo

echo "🔍 Step 9: Checking if services are now listening..."
echo "Backend (port 3001):"
netstat -tlnp | grep :3001 || echo "❌ Still not listening"

echo "User Frontend (port 8080):"
netstat -tlnp | grep :8080 || echo "❌ Still not listening"

echo "Admin Frontend (port 8081):"
netstat -tlnp | grep :8081 || echo "❌ Still not listening"
echo

echo "🔍 Step 10: Testing service endpoints..."
echo "Testing backend health:"
curl -s http://localhost:3001/health || curl -s http://localhost:3001/ || echo "❌ Backend not responding"

echo "Testing user frontend:"
curl -s -I http://localhost:8080/ | head -1 || echo "❌ User frontend not responding"

echo "Testing admin frontend:"
curl -s -I http://localhost:8081/ | head -1 || echo "❌ Admin frontend not responding"
echo

echo "========================================="
echo "✅ Diagnostic completed!"
echo "========================================="
echo
echo "📊 If services are still not working:"
echo "1. Check PM2 logs: pm2 logs"
echo "2. Check individual service logs: pm2 logs win5x-backend"
echo "3. Restart specific service: pm2 restart win5x-backend"
echo "4. Check nginx logs: tail -f /var/log/nginx/error.log"
echo
