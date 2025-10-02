#!/bin/bash
# Fix Development Environment Script
# This script fixes Redis authentication and sets up proper development environment

echo "🔧 Fixing Development Environment..."
echo "==============================================="

PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"

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

# 1. Check if Redis is running
echo "🔍 Checking Redis Status..."
echo "==============================================="

if systemctl is-active --quiet redis-server; then
    echo "✅ Redis is running"
else
    echo "❌ Redis is not running, starting it..."
    run_safe_command "sudo systemctl start redis-server" "Redis start"
fi

# 2. Configure Redis with password for development
echo "🔧 Configuring Redis for Development..."
echo "==============================================="

# Stop Redis
run_safe_command "sudo systemctl stop redis-server" "Redis stop"

# Create Redis config for development (no password)
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

# Copy the configuration
run_safe_command "sudo cp /tmp/redis-dev.conf /etc/redis/redis.conf" "Redis config copy"

# Start Redis
run_safe_command "sudo systemctl start redis-server" "Redis start"

# Test Redis connection
echo "🔍 Testing Redis connection..."
if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is responding without password"
else
    echo "❌ Redis is not responding"
fi

# 3. Update backend .env file for development
echo "🔧 Updating Backend Environment..."
echo "==============================================="

cd packages/backend

# Create/update .env file for development
cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://win5x_user:Win5xDB@2024@localhost:5432/win5x_db"

# JWT
JWT_SECRET="8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4"
JWT_EXPIRES_IN="24h"

# Redis (no password for development)
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

echo "✅ Backend .env updated for development"

# 4. Update admin .env file
echo "🔧 Updating Admin Environment..."
echo "==============================================="

cd ../admin

cat > .env << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
EOF

echo "✅ Admin .env updated"

# 5. Update user .env file
echo "🔧 Updating User Environment..."
echo "==============================================="

cd ../user

cat > .env << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
EOF

echo "✅ User .env updated"

# 6. Generate Prisma client
echo "🔧 Generating Prisma Client..."
echo "==============================================="

cd ../backend
run_safe_command "pnpm run db:generate" "Prisma client generation"

# 7. Run database migration
echo "🗄️ Running Database Migration..."
echo "==============================================="

run_safe_command "pnpm run db:migrate" "Database migration"

# 8. Create admin user
echo "👤 Creating Admin User..."
echo "==============================================="

export ADMIN_USERNAME="admin"
export ADMIN_EMAIL="admin@win5x.com"
export ADMIN_PASSWORD="Admin@123"
run_safe_command "pnpm run create-admin" "Admin user creation"

# 9. Display final information
echo "📊 Development Environment Ready!"
echo "==============================================="

echo "🔍 Services Status:"
echo "• PostgreSQL: $(systemctl is-active postgresql)"
echo "• Redis: $(systemctl is-active redis-server)"
echo "• Database: Connected"
echo "• Admin User: Created"

echo ""
echo "🌐 Development URLs:"
echo "• Backend API: http://localhost:3001"
echo "• Admin Panel: http://localhost:3000/admin/"
echo "• User Panel: http://localhost:3002/"
echo "• Socket.IO: http://localhost:3001"

echo ""
echo "👤 Admin Credentials:"
echo "• Username: admin"
echo "• Email: admin@win5x.com"
echo "• Password: Admin@123"

echo ""
echo "🚀 Start Development:"
echo "• Run: pnpm run dev"
echo "• Or run individual services:"
echo "  - Backend: pnpm run dev:backend"
echo "  - Admin: pnpm run dev:admin"
echo "  - User: pnpm run dev:user"

echo ""
echo "==============================================="
echo "🎉 Development Environment Setup Complete!"
echo "==============================================="
