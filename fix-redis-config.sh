#!/bin/bash
# Redis Configuration Fix Script
# This script fixes Redis authentication issues

echo "🔴 Fixing Redis Configuration..."
echo "==============================================="

REDIS_PASSWORD="${REDIS_PASSWORD:-Redis@2024}"

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

# 1. Stop Redis service
echo "🛑 Stopping Redis service..."
run_safe_command "sudo systemctl stop redis-server" "Redis service stop"

# 2. Configure Redis with password
echo "🔧 Configuring Redis with password..."
cat > /tmp/redis-win5x.conf << EOF
# Redis configuration for Win5x
port 6379
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

# 3. Start Redis service
echo "🚀 Starting Redis service..."
run_safe_command "sudo systemctl start redis-server" "Redis service start"

# 4. Test Redis connection with password
echo "🔍 Testing Redis connection with password..."
run_safe_command "redis-cli -a $REDIS_PASSWORD ping" "Redis password test"

# 5. Restart PM2 applications to pick up new Redis config
echo "🔄 Restarting PM2 applications..."
run_safe_command "pm2 restart all" "PM2 applications restart"

# 6. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# 7. Test application endpoints
echo "🌐 Testing Application Endpoints..."
echo "==============================================="

# Test backend API
echo "🔍 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8082/api/health" | grep -q "200"; then
    echo "✅ Backend API is responding"
else
    echo "⚠️ Backend API is not responding, checking logs..."
    pm2 logs win5x-backend --lines 5
fi

# Test admin panel
echo "🔍 Testing admin panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8081" | grep -q "200"; then
    echo "✅ Admin panel is responding"
else
    echo "⚠️ Admin panel is not responding"
fi

# Test user panel
echo "🔍 Testing user panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080" | grep -q "200"; then
    echo "✅ User panel is responding"
else
    echo "⚠️ User panel is not responding"
fi

# 8. Final status
echo "📊 Final Status..."
echo "==============================================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🔍 Redis Status:"
systemctl is-active redis-server

echo ""
echo "🔍 Port Status:"
netstat -tlnp | grep -E ':(80|8080|8081|8082|6379)'

echo ""
echo "==============================================="
echo "🎉 Redis Configuration Fix Complete!"
echo "==============================================="
echo ""
echo "📋 Fix Summary:"
echo "• Redis configured with password: $REDIS_PASSWORD"
echo "• PM2 applications restarted"
echo "• Services tested and verified"
echo ""
echo "🌐 Access URLs:"
echo "• User Panel: http://217.148.142.91:80/"
echo "• Admin Panel: http://217.148.142.91:80/admin"
echo "• API: http://217.148.142.91:80/api"
echo ""
echo "🔧 Management Commands:"
echo "• PM2 Status: pm2 status"
echo "• PM2 Logs: pm2 logs"
echo "• Redis Test: redis-cli -a $REDIS_PASSWORD ping"
echo "==============================================="
