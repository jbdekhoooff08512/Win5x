#!/bin/bash

# Quick Fix for 502 Bad Gateway Errors
echo "========================================="
echo "    Quick Fix for 502 Bad Gateway"
echo "========================================="
echo

cd /var/www/kart

echo "🛑 Step 1: Stopping all services..."
pm2 delete all 2>/dev/null || true
pkill -f "serve.*packages" 2>/dev/null || true
echo "✅ All services stopped"
echo

echo "🔨 Step 2: Rebuilding project..."
pnpm run build
echo "✅ Project rebuilt"
echo

echo "📦 Step 3: Installing serve globally..."
npm install -g serve
echo "✅ Serve installed"
echo

echo "📁 Step 4: Creating logs directory..."
mkdir -p logs
echo "✅ Logs directory created"
echo

echo "🚀 Step 5: Starting services manually to test..."

# Start backend
echo "Starting backend on port 3001..."
cd packages/backend
node dist/index.js &
BACKEND_PID=$!
cd ../..

# Wait a moment for backend to start
sleep 2

# Start user frontend
echo "Starting user frontend on port 8080..."
serve -s packages/user/dist -l 8080 &
USER_PID=$!

# Start admin frontend  
echo "Starting admin frontend on port 8081..."
serve -s packages/admin/dist -l 8081 &
ADMIN_PID=$!

echo "✅ Services started manually"
echo

echo "🔍 Step 6: Checking if services are listening..."
sleep 3

if netstat -tlnp | grep :3001; then
    echo "✅ Backend is listening on port 3001"
else
    echo "❌ Backend failed to start on port 3001"
fi

if netstat -tlnp | grep :8080; then
    echo "✅ User frontend is listening on port 8080"
else
    echo "❌ User frontend failed to start on port 8080"
fi

if netstat -tlnp | grep :8081; then
    echo "✅ Admin frontend is listening on port 8081"
else
    echo "❌ Admin frontend failed to start on port 8081"
fi
echo

echo "🧪 Step 7: Testing service endpoints..."
echo "Testing backend:"
curl -s -I http://localhost:3001/ | head -1 || echo "❌ Backend not responding"

echo "Testing user frontend:"
curl -s -I http://localhost:8080/ | head -1 || echo "❌ User frontend not responding"

echo "Testing admin frontend:"
curl -s -I http://localhost:8081/ | head -1 || echo "❌ Admin frontend not responding"
echo

echo "🛑 Step 8: Stopping manual processes..."
kill $BACKEND_PID $USER_PID $ADMIN_PID 2>/dev/null || true
echo "✅ Manual processes stopped"
echo

echo "🚀 Step 9: Starting with PM2..."
pm2 start ecosystem.config.js
pm2 save
echo "✅ PM2 services started"
echo

echo "🔍 Step 10: Final verification..."
sleep 3
pm2 status
echo

echo "🌐 Step 11: Testing through Nginx..."
echo "Testing main site:"
curl -s -I http://localhost/ | head -1 || echo "❌ Main site not responding"

echo "Testing admin panel:"
curl -s -I http://localhost/admin/ | head -1 || echo "❌ Admin panel not responding"

echo "Testing API:"
curl -s -I http://localhost/api/ | head -1 || echo "❌ API not responding"
echo

echo "========================================="
echo "✅ Quick fix completed!"
echo "========================================="
echo
echo "🌐 Your application should now be accessible at:"
echo "   Main Site: http://217.148.142.91"
echo "   Admin Panel: http://217.148.142.91/admin"
echo "   API: http://217.148.142.91/api"
echo
echo "📊 To monitor services:"
echo "   pm2 status"
echo "   pm2 logs"
echo
