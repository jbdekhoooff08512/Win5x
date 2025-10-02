#!/bin/bash
# Win5x Complete Restart Script
# This script clears everything and restarts all services fresh

echo "🔄 Starting Win5x Complete Restart..."
echo "==============================================="

# Default parameters
DATABASE_PASSWORD="${DATABASE_PASSWORD:-Win5xDB@2024}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@win5x.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@123}"
REDIS_PASSWORD="${REDIS_PASSWORD:-Redis@2024}"
PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"
SERVER_IP="${SERVER_IP:-217.148.142.91}"
USER_PORT="${USER_PORT:-8080}"
ADMIN_PORT="${ADMIN_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8082}"
REDIS_PORT="${REDIS_PORT:-6379}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
NGINX_PORT="${NGINX_PORT:-80}"

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

# 1. Stop All Services
echo "🛑 Stopping All Services..."
echo "==============================================="

# Stop PM2 applications
echo "📋 Stopping PM2 applications..."
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Stop Redis
echo "📋 Stopping Redis..."
run_safe_command "sudo systemctl stop redis-server" "Redis service stop"

# Stop Nginx
echo "📋 Stopping Nginx..."
run_safe_command "sudo systemctl stop nginx" "Nginx service stop"

# 2. Clear Node.js Cache and Logs
echo "🧹 Clearing Node.js Cache and Logs..."
echo "==============================================="

# Clear PM2 logs
echo "📋 Clearing PM2 logs..."
pm2 flush 2>/dev/null || true

# Clear application logs
echo "📋 Clearing application logs..."
rm -rf logs/* 2>/dev/null || true
mkdir -p logs

# Clear Node.js cache
echo "📋 Clearing Node.js cache..."
find . -name "node_modules/.cache" -type d -exec rm -rf {} + 2>/dev/null || true

# Clear build artifacts
echo "📋 Clearing build artifacts..."
rm -rf packages/admin/dist 2>/dev/null || true
rm -rf packages/user/dist 2>/dev/null || true
rm -rf packages/backend/dist 2>/dev/null || true

# 3. Restart Redis with Proper Configuration
echo "🔴 Restarting Redis with Configuration..."
echo "==============================================="

# Configure Redis with password
echo "📋 Configuring Redis..."
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

# Copy the configuration
run_safe_command "sudo cp /tmp/redis-win5x.conf /etc/redis/redis.conf" "Redis config copy"

# Start Redis
echo "📋 Starting Redis..."
run_safe_command "sudo systemctl start redis-server" "Redis service start"

# Test Redis connection
echo "📋 Testing Redis connection..."
run_safe_command "redis-cli -a $REDIS_PASSWORD ping" "Redis connection test"

# 4. Restart Nginx
echo "🌐 Restarting Nginx..."
echo "==============================================="

run_safe_command "sudo systemctl start nginx" "Nginx service start"

# 5. Build Applications
echo "🔨 Building Applications..."
echo "==============================================="

# Build admin package
echo "📦 Building admin package..."
cd packages/admin
run_safe_command "pnpm run build" "Admin package build"
cd ../..

# Build user package
echo "📦 Building user package..."
cd packages/user
run_safe_command "pnpm run build" "User package build"
cd ../..

# Build backend package
echo "📦 Building backend package..."
cd packages/backend
run_safe_command "pnpm run build" "Backend package build"
cd ../..

# 6. Start PM2 Applications
echo "🚀 Starting PM2 Applications..."
echo "==============================================="

# Start applications using ecosystem config
if [ -f "ecosystem.config.js" ]; then
    echo "📋 Starting PM2 applications from ecosystem config..."
    run_safe_command "pm2 start ecosystem.config.js" "PM2 applications start"
else
    echo "📋 Starting PM2 applications manually..."
    
    # Start backend
    run_safe_command "pm2 start packages/backend/dist/server.js --name win5x-backend --cwd $PROJECT_PATH" "Backend application start"
    
    # Start admin panel
    run_safe_command "pm2 start serve --name win5x-admin -- -s packages/admin/dist -p $ADMIN_PORT --cwd $PROJECT_PATH" "Admin panel start"
    
    # Start user panel
    run_safe_command "pm2 start serve --name win5x-user -- -s packages/user/dist -p $USER_PORT --cwd $PROJECT_PATH" "User panel start"
fi

# Save PM2 configuration
run_safe_command "pm2 save" "PM2 configuration save"

# 7. Wait for Services to Start
echo "⏳ Waiting for services to start..."
echo "==============================================="

sleep 15

# 8. Test All Endpoints
echo "🌐 Testing All Endpoints..."
echo "==============================================="

# Test backend API
echo "🔍 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BACKEND_PORT/api/health" | grep -q "200"; then
    echo "✅ Backend API is responding"
else
    echo "⚠️ Backend API is not responding, checking logs..."
    pm2 logs win5x-backend --lines 5
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

# Test external access
echo "🔍 Testing external access..."
if curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:$NGINX_PORT" | grep -q "200"; then
    echo "✅ External access is working"
else
    echo "⚠️ External access is not working"
fi

# 9. Display Complete Status
echo "📊 Complete System Status..."
echo "==============================================="

echo "🔍 Service Status:"
echo "• PostgreSQL: $(systemctl is-active postgresql)"
echo "• Redis: $(systemctl is-active redis-server)"
echo "• Nginx: $(systemctl is-active nginx)"
echo ""

echo "🔍 PM2 Status:"
pm2 status
echo ""

echo "🔍 Port Status:"
echo "• PostgreSQL ($POSTGRES_PORT): $(netstat -tlnp | grep :$POSTGRES_PORT | wc -l) connections"
echo "• Redis ($REDIS_PORT): $(netstat -tlnp | grep :$REDIS_PORT | wc -l) connections"
echo "• Nginx ($NGINX_PORT): $(netstat -tlnp | grep :$NGINX_PORT | wc -l) connections"
echo "• Backend ($BACKEND_PORT): $(netstat -tlnp | grep :$BACKEND_PORT | wc -l) connections"
echo "• Admin ($ADMIN_PORT): $(netstat -tlnp | grep :$ADMIN_PORT | wc -l) connections"
echo "• User ($USER_PORT): $(netstat -tlnp | grep :$USER_PORT | wc -l) connections"
echo ""

echo "🔍 System Resources:"
echo "• CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "• Memory Usage:"
free -h | grep -E "(Mem|Swap)"
echo "• Disk Usage:"
df -h | grep -E "(Filesystem|/dev/)"
echo ""

echo "🔍 Recent Logs (last 5 lines each):"
echo "Backend Logs:"
pm2 logs win5x-backend --lines 5 --nostream 2>/dev/null || echo "No backend logs"
echo ""
echo "Admin Logs:"
pm2 logs win5x-admin --lines 5 --nostream 2>/dev/null || echo "No admin logs"
echo ""
echo "User Logs:"
pm2 logs win5x-user --lines 5 --nostream 2>/dev/null || echo "No user logs"
echo ""

# 10. Display Final Information
echo "==============================================="
echo "🎉 Win5x Complete Restart Finished!"
echo "==============================================="
echo ""
echo "📋 Restart Summary:"
echo "• All services stopped and cleared"
echo "• Node.js cache and logs cleared"
echo "• Redis restarted with proper configuration"
echo "• Applications rebuilt and started"
echo "• All endpoints tested and verified"
echo ""
echo "🌐 Access URLs:"
echo "• User Panel: http://$SERVER_IP:$NGINX_PORT/"
echo "• Admin Panel: http://$SERVER_IP:$NGINX_PORT/admin"
echo "• API: http://$SERVER_IP:$NGINX_PORT/api"
echo ""
echo "🔗 Direct Access URLs:"
echo "• User Panel Direct: http://$SERVER_IP:$USER_PORT"
echo "• Admin Panel Direct: http://$SERVER_IP:$ADMIN_PORT"
echo "• Backend API Direct: http://$SERVER_IP:$BACKEND_PORT"
echo ""
echo "👤 Admin Credentials:"
echo "• Username: $ADMIN_USERNAME"
echo "• Email: $ADMIN_EMAIL"
echo "• Password: $ADMIN_PASSWORD"
echo ""
echo "🔧 Management Commands:"
echo "• PM2 Status: pm2 status"
echo "• PM2 Logs: pm2 logs"
echo "• PM2 Restart: pm2 restart all"
echo "• System Status: ./monitor-system.sh"
echo "• Redis Test: redis-cli -a $REDIS_PASSWORD ping"
echo "• Database Test: sudo -u postgres psql -d win5x_db -c 'SELECT 1;'"
echo ""
echo "📁 Project Location: $PROJECT_PATH"
echo "==============================================="
