#!/bin/bash
# Win5x Run Applications Script
# This script only runs backend and frontend applications

echo "🚀 Starting Win5x Applications..."
echo "==============================================="

# Default parameters
PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"
SERVER_IP="${SERVER_IP:-217.148.142.91}"
USER_PORT="${USER_PORT:-8080}"
ADMIN_PORT="${ADMIN_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8082}"

# Function to run command with error handling
run_safe_command() {
    local command="$1"
    local description="$2"
    
    echo "📋 $description"
    if eval "$command"; then
        echo "✅ $description - Success"
        return 0
    else
        echo "❌ $description - Failed"
        return 1
    fi
}

# Navigate to project directory
cd "$PROJECT_PATH" || {
    echo "❌ Cannot navigate to project directory: $PROJECT_PATH"
    exit 1
}

echo "📁 Working in project directory: $PROJECT_PATH"

# 1. Stop existing PM2 processes
echo "🛑 Stopping existing PM2 processes..."
echo "==============================================="

pm2 delete all 2>/dev/null || true

# 2. Build applications (if needed)
echo "🔨 Building Applications..."
echo "==============================================="

# Build admin package
if [ ! -d "packages/admin/dist" ]; then
    echo "📦 Building admin package..."
    cd packages/admin
    run_safe_command "pnpm run build" "Admin package build"
    cd ../..
fi

# Build user package
if [ ! -d "packages/user/dist" ]; then
    echo "📦 Building user package..."
    cd packages/user
    run_safe_command "pnpm run build" "User package build"
    cd ../..
fi

# Build backend package
if [ ! -d "packages/backend/dist" ]; then
    echo "📦 Building backend package..."
    cd packages/backend
    run_safe_command "pnpm run build" "Backend package build"
    cd ../..
fi

# 3. Start Backend Application
echo "🔧 Starting Backend Application..."
echo "==============================================="

run_safe_command "pm2 start packages/backend/dist/server.js --name win5x-backend --cwd $PROJECT_PATH" "Backend application start"

# 4. Start Frontend Applications
echo "🌐 Starting Frontend Applications..."
echo "==============================================="

# Start admin panel
run_safe_command "pm2 start serve --name win5x-admin -- -s packages/admin/dist -p $ADMIN_PORT --cwd $PROJECT_PATH" "Admin panel start"

# Start user panel
run_safe_command "pm2 start serve --name win5x-user -- -s packages/user/dist -p $USER_PORT --cwd $PROJECT_PATH" "User panel start"

# 5. Save PM2 configuration
echo "💾 Saving PM2 configuration..."
echo "==============================================="

run_safe_command "pm2 save" "PM2 configuration save"

# 6. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# 7. Display Status
echo "📊 Application Status..."
echo "==============================================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🔍 Port Status:"
echo "• Backend ($BACKEND_PORT): $(netstat -tlnp | grep :$BACKEND_PORT | wc -l) connections"
echo "• Admin ($ADMIN_PORT): $(netstat -tlnp | grep :$ADMIN_PORT | wc -l) connections"
echo "• User ($USER_PORT): $(netstat -tlnp | grep :$USER_PORT | wc -l) connections"

echo ""
echo "🔍 Application URLs:"
echo "• Backend API: http://localhost:$BACKEND_PORT"
echo "• Admin Panel: http://localhost:$ADMIN_PORT"
echo "• User Panel: http://localhost:$USER_PORT"

echo ""
echo "🔍 External URLs:"
echo "• Backend API: http://$SERVER_IP:$BACKEND_PORT"
echo "• Admin Panel: http://$SERVER_IP:$ADMIN_PORT"
echo "• User Panel: http://$SERVER_IP:$USER_PORT"

# 8. Test Applications
echo "🌐 Testing Applications..."
echo "==============================================="

# Test backend API
echo "🔍 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BACKEND_PORT/api/health" | grep -q "200"; then
    echo "✅ Backend API is responding"
else
    echo "⚠️ Backend API is not responding"
fi

# Test admin panel
echo "🔍 Testing admin panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ADMIN_PORT" | grep -q "200"; then
    echo "✅ Admin panel is responding"
else
    echo "⚠️ Admin panel is not responding"
fi

# Test user panel
echo "🔍 Testing user panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$USER_PORT" | grep -q "200"; then
    echo "✅ User panel is responding"
else
    echo "⚠️ User panel is not responding"
fi

# 9. Display Final Information
echo "==============================================="
echo "🎉 Win5x Applications Started!"
echo "==============================================="
echo ""
echo "📋 Applications Running:"
echo "• Backend API (Node.js)"
echo "• Admin Panel (React)"
echo "• User Panel (React)"
echo ""
echo "🌐 Access URLs:"
echo "• Backend API: http://$SERVER_IP:$BACKEND_PORT"
echo "• Admin Panel: http://$SERVER_IP:$ADMIN_PORT"
echo "• User Panel: http://$SERVER_IP:$USER_PORT"
echo ""
echo "🔧 Management Commands:"
echo "• PM2 Status: pm2 status"
echo "• PM2 Logs: pm2 logs"
echo "• PM2 Restart: pm2 restart all"
echo "• PM2 Stop: pm2 stop all"
echo "• PM2 Delete: pm2 delete all"
echo ""
echo "📁 Project Location: $PROJECT_PATH"
echo "==============================================="
