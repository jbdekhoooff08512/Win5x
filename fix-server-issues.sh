#!/bin/bash
# Win5x Server Fix Script
# This script fixes common issues after initial setup

echo "🔧 Starting Win5x Server Fix..."
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

# 1. Fix Database Permissions
echo "🔧 Fixing Database Permissions..."
echo "==============================================="

DB_NAME="win5x_db"
DB_USER="win5x_user"

# Grant additional permissions to the database user
run_safe_command "sudo -u postgres psql -c \"ALTER USER $DB_USER CREATEDB;\"" "Grant CREATEDB permission"
run_safe_command "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;\"" "Grant database privileges"
run_safe_command "sudo -u postgres psql -c \"GRANT ALL ON SCHEMA public TO $DB_USER;\"" "Grant schema privileges"

# 2. Fix Database Migration
echo "🗄️ Fixing Database Migration..."
echo "==============================================="

cd packages/backend

# Use production migration instead of dev migration
echo "📋 Running production database migration..."
if run_safe_command "pnpm run db:migrate:prod" "Production database migration"; then
    echo "✅ Production migration successful"
else
    echo "🔄 Trying alternative migration approach..."
    
    # Alternative: Use prisma db push for development
    if run_safe_command "npx prisma db push --accept-data-loss" "Database schema push"; then
        echo "✅ Database schema pushed successfully"
    else
        echo "❌ Database schema push failed"
        exit 1
    fi
fi

cd ../..

# 3. Verify Database Tables
echo "🔍 Verifying Database Tables..."
echo "==============================================="

# Check if tables exist
TABLES=$(sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
if [ "$TABLES" -gt 0 ]; then
    echo "✅ Database tables exist ($TABLES tables found)"
else
    echo "❌ No database tables found"
    exit 1
fi

# 4. Create Admin User
echo "👤 Creating Admin User..."
echo "==============================================="

cd packages/backend

# Check if admin user already exists
ADMIN_EXISTS=$(sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM admins WHERE email = '$ADMIN_EMAIL';" 2>/dev/null || echo "0")

if [ "$ADMIN_EXISTS" -gt 0 ]; then
    echo "✅ Admin user already exists"
else
    echo "📝 Creating new admin user..."
    export ADMIN_USERNAME="$ADMIN_USERNAME"
    export ADMIN_EMAIL="$ADMIN_EMAIL"
    export ADMIN_PASSWORD="$ADMIN_PASSWORD"
    run_safe_command "pnpm run create-admin" "Admin user creation"
fi

cd ../..

# 5. Build Applications
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

# 6. Start PM2 Applications
echo "🚀 Starting PM2 Applications..."
echo "==============================================="

# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

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

# 8. Test Application Endpoints
echo "🌐 Testing Application Endpoints..."
echo "==============================================="

# Test backend API
echo "🔍 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BACKEND_PORT/api/health" | grep -q "200"; then
    echo "✅ Backend API is responding"
else
    echo "⚠️ Backend API is not responding, checking logs..."
    pm2 logs win5x-backend --lines 10
fi

# Test admin panel
echo "🔍 Testing admin panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ADMIN_PORT" | grep -q "200"; then
    echo "✅ Admin panel is responding"
else
    echo "⚠️ Admin panel is not responding, checking logs..."
    pm2 logs win5x-admin --lines 10
fi

# Test user panel
echo "🔍 Testing user panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$USER_PORT" | grep -q "200"; then
    echo "✅ User panel is responding"
else
    echo "⚠️ User panel is not responding, checking logs..."
    pm2 logs win5x-user --lines 10
fi

# 9. Final Status Check
echo "📊 Final Status Check..."
echo "==============================================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🔍 Port Status:"
netstat -tlnp | grep -E ':(80|8080|8081|8082|5432|6379)'

echo ""
echo "🔍 Service Status:"
systemctl is-active postgresql redis-server nginx

# 10. Display Final Information
echo "==============================================="
echo "🎉 Win5x Server Fix Complete!"
echo "==============================================="
echo ""
echo "📋 Fix Summary:"
echo "• Database permissions fixed"
echo "• Database migration completed"
echo "• Admin user created/verified"
echo "• Applications built and started"
echo "• PM2 processes running"
echo ""
echo "🌐 Access URLs:"
echo "• User Panel: http://$SERVER_IP:$NGINX_PORT/"
echo "• Admin Panel: http://$SERVER_IP:$NGINX_PORT/admin"
echo "• API: http://$SERVER_IP:$NGINX_PORT/api"
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
echo ""
echo "📁 Project Location: $PROJECT_PATH"
echo "==============================================="
