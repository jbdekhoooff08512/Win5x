#!/bin/bash

# Quick Win5x Server Restart and Error Check
echo "========================================="
echo "    Win5x Server Restart & Error Check"
echo "========================================="
echo

# Stop all services
echo "🔄 Stopping all PM2 services..."
pm2 stop all
pm2 delete all
echo

# Kill any hanging processes on our ports
echo "🧹 Cleaning up hanging processes..."
for port in 8080 8081 8082; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo "Killing process $pid on port $port"
        kill -9 $pid 2>/dev/null
    fi
done
echo

# Install dependencies and build
echo "📦 Installing dependencies..."
cd /var/www/kart
pnpm install --prod
echo

echo "🔨 Building project..."
pnpm run build
echo

# Start services
echo "🚀 Starting services..."
pm2 start ecosystem.config.js
pm2 save
echo

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10
echo

# Check status
echo "📊 PM2 Status:"
pm2 status
echo

echo "🔌 Port Check:"
netstat -tuln | grep -E ":(8080|8081|8082) "
echo

echo "🏥 Health Check:"
curl -s http://localhost:8080 > /dev/null && echo "✅ User Frontend (8080): OK" || echo "❌ User Frontend (8080): FAIL"
curl -s http://localhost:8081 > /dev/null && echo "✅ Admin Frontend (8081): OK" || echo "❌ Admin Frontend (8081): FAIL"
curl -s http://localhost:8082/api/health > /dev/null && echo "✅ Backend API (8082): OK" || echo "❌ Backend API (8082): FAIL"
echo

echo "📋 Recent Error Logs:"
echo "--- Backend Errors ---"
tail -10 /var/www/kart/logs/backend-error.log 2>/dev/null || echo "No backend error log found"
echo
echo "--- Admin Errors ---"
tail -10 /var/www/kart/logs/admin-error.log 2>/dev/null || echo "No admin error log found"
echo
echo "--- User Errors ---"
tail -10 /var/www/kart/logs/user-error.log 2>/dev/null || echo "No user error log found"
echo

echo "🌐 Application URLs:"
echo "   User Panel:  http://217.148.142.91:8080"
echo "   Admin Panel: http://217.148.142.91:8081"
echo "   Backend API: http://217.148.142.91:8082"
echo

echo "✅ Restart and check complete!"
