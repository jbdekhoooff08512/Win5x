#!/bin/bash
# Quick Redis Fix Script
# This script fixes the Redis authentication issue for development

echo "🔧 Quick Redis Fix for Development..."
echo "==============================================="

# Navigate to backend directory
cd packages/backend || {
    echo "❌ Cannot navigate to backend directory"
    exit 1
}

echo "📁 Working in backend directory"

# Create .env file with correct Redis URL (no password)
echo "🔧 Creating Backend .env File..."
cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://win5x_user:Win5xDB@2024@localhost:5432/win5x_db"

# JWT
JWT_SECRET="8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4"
JWT_EXPIRES_IN="24h"

# Redis (NO PASSWORD for development)
REDIS_URL="redis://localhost:6379"

# Server
PORT=3001
NODE_ENV=development

# Admin credentials
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@win5x.com"
ADMIN_PASSWORD="Admin@123"

# Security
BCRYPT_ROUNDS=12

# File uploads
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880

# Game settings
GAME_BETTING_DURATION=30
GAME_SPIN_DURATION=10
GAME_RESULT_DURATION=15

# Payment settings
USDT_TO_INR_RATE=83.0
DEPOSIT_BONUS_PERCENTAGE=5

# Referral settings
REFERRAL_LEVEL1_PERCENTAGE=5
REFERRAL_LEVEL2_PERCENTAGE=3
REFERRAL_LEVEL3_PERCENTAGE=1

# Attendance
ATTENDANCE_DAY7_AMOUNT=60
EOF

echo "✅ Backend .env created with Redis URL: redis://localhost:6379"

# Create admin .env
cd ../admin
cat > .env << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
EOF

echo "✅ Admin .env created"

# Create user .env
cd ../user
cat > .env << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
EOF

echo "✅ User .env created"

# Go back to root
cd ../..

echo ""
echo "🔧 Redis Configuration Check..."
echo "==============================================="

# Check if Redis is running without password
if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is running and accessible without password"
else
    echo "❌ Redis is not accessible, trying to fix..."
    
    # Stop Redis
    sudo systemctl stop redis-server 2>/dev/null || true
    
    # Create Redis config without password
    cat > /tmp/redis-dev.conf << 'EOF'
# Redis configuration for development
port 6379
bind 127.0.0.1
# No password for development
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF

    # Apply config
    sudo cp /tmp/redis-dev.conf /etc/redis/redis.conf
    sudo systemctl start redis-server
    
    # Test again
    if redis-cli ping | grep -q "PONG"; then
        echo "✅ Redis fixed and running without password"
    else
        echo "❌ Redis still not working"
    fi
fi

echo ""
echo "📊 Environment Files Created:"
echo "• Backend: packages/backend/.env"
echo "• Admin: packages/admin/.env"
echo "• User: packages/user/.env"

echo ""
echo "🌐 Development URLs:"
echo "• Backend API: http://localhost:3001"
echo "• Admin Panel: http://localhost:3000/admin/"
echo "• User Panel: http://localhost:3002/"

echo ""
echo "🚀 Next Steps:"
echo "1. Stop current development server (Ctrl+C)"
echo "2. Run: pnpm run dev"
echo "3. Redis should work without authentication errors"

echo ""
echo "==============================================="
echo "🎉 Redis Fix Complete!"
echo "==============================================="

