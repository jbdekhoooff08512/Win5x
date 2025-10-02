#!/bin/bash
# Win5x Server Initialization Script
# This script handles post-setup initialization tasks
# Run this after the main setup script completes

# Default parameters
DATABASE_PASSWORD="${DATABASE_PASSWORD:-Win5xDB@2024}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@win5x.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@123}"
REDIS_PASSWORD="${REDIS_PASSWORD:-Redis@2024}"
PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"
SERVER_IP="${SERVER_IP:-localhost}"
USER_PORT="${USER_PORT:-8080}"
ADMIN_PORT="${ADMIN_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8082}"
REDIS_PORT="${REDIS_PORT:-6379}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
NGINX_PORT="${NGINX_PORT:-80}"

echo "🚀 Starting Win5x Server Initialization..."
echo "==============================================="

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

# Function to check service status
check_service_status() {
    local service_name="$1"
    local description="$2"
    
    echo "🔍 Checking $description..."
    if systemctl is-active --quiet "$service_name"; then
        echo "✅ $description is running"
        return 0
    else
        echo "❌ $description is not running"
        return 1
    fi
}

# Function to check port availability
check_port() {
    local port="$1"
    local description="$2"
    
    echo "🔍 Checking $description on port $port..."
    if netstat -tlnp | grep -q ":$port "; then
        echo "✅ $description is listening on port $port"
        return 0
    else
        echo "❌ $description is not listening on port $port"
        return 1
    fi
}

# Navigate to project directory
cd "$PROJECT_PATH" || {
    echo "❌ Cannot navigate to project directory: $PROJECT_PATH"
    exit 1
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Not in the correct project directory. Please run from: $PROJECT_PATH"
    exit 1
fi

echo "📁 Working in project directory: $PROJECT_PATH"

# 1. Verify Services Status
echo "🔍 Verifying Services Status..."
echo "==============================================="

services_ok=true
check_service_status "postgresql" "PostgreSQL" || services_ok=false
check_service_status "redis-server" "Redis" || services_ok=false
check_service_status "nginx" "Nginx" || services_ok=false

if [ "$services_ok" = false ]; then
    echo "❌ Some services are not running. Please check the main setup script."
    exit 1
fi

# 2. Check Port Availability
echo "🔍 Checking Port Availability..."
echo "==============================================="

ports_ok=true
check_port "$POSTGRES_PORT" "PostgreSQL" || ports_ok=false
check_port "$REDIS_PORT" "Redis" || ports_ok=false
check_port "$NGINX_PORT" "Nginx" || ports_ok=false

if [ "$ports_ok" = false ]; then
    echo "❌ Some ports are not available. Please check for conflicts."
    exit 1
fi

# 3. Database Connection Test
echo "🗄️ Testing Database Connection..."
echo "==============================================="

DB_NAME="win5x_db"
DB_USER="win5x_user"

if ! run_safe_command "sudo -u postgres psql -c 'SELECT 1;' -d $DB_NAME" "Database connection test"; then
    echo "❌ Database connection failed. Please check PostgreSQL setup."
    exit 1
fi

# 4. Redis Connection Test
echo "🔴 Testing Redis Connection..."
echo "==============================================="

if ! run_safe_command "redis-cli -p $REDIS_PORT -a $REDIS_PASSWORD ping" "Redis connection test"; then
    echo "❌ Redis connection failed. Please check Redis setup."
    exit 1
fi

# 5. Build Project (if not already built)
echo "🔨 Building Project..."
echo "==============================================="

if [ ! -d "packages/admin/dist" ]; then
    echo "📦 Building admin package..."
    cd packages/admin
    run_safe_command "pnpm run build" "Admin package build"
    cd ../..
fi

if [ ! -d "packages/user/dist" ]; then
    echo "📦 Building user package..."
    cd packages/user
    run_safe_command "pnpm run build" "User package build"
    cd ../..
fi

if [ ! -d "packages/backend/dist" ]; then
    echo "📦 Building backend package..."
    cd packages/backend
    run_safe_command "pnpm run build" "Backend package build"
    cd ../..
fi

# 6. Database Schema Setup
echo "🗄️ Setting up Database Schema..."
echo "==============================================="

cd packages/backend

# Generate Prisma client
run_safe_command "pnpm run db:generate" "Prisma client generation"

# Run migrations
run_safe_command "pnpm run db:migrate" "Database migration"

# Seed database (if seed script exists)
if [ -f "src/database/seed.ts" ]; then
    echo "🌱 Seeding database..."
    run_safe_command "pnpm run db:seed" "Database seeding"
fi

cd ../..

# 7. Create Admin User (if not exists)
echo "👤 Creating Admin User..."
echo "==============================================="

cd packages/backend

# Check if admin user already exists
if sudo -u postgres psql -d "$DB_NAME" -c "SELECT id FROM users WHERE email = '$ADMIN_EMAIL';" | grep -q "1 row"; then
    echo "✅ Admin user already exists"
else
    echo "📝 Creating new admin user..."
    export ADMIN_USERNAME="$ADMIN_USERNAME"
    export ADMIN_EMAIL="$ADMIN_EMAIL"
    export ADMIN_PASSWORD="$ADMIN_PASSWORD"
    run_safe_command "pnpm run create-admin" "Admin user creation"
fi

cd ../..

# 8. Start PM2 Applications
echo "🚀 Starting PM2 Applications..."
echo "==============================================="

# Check if PM2 is running
if pm2 status >/dev/null 2>&1; then
    echo "📋 Current PM2 status:"
    pm2 status
    
    # Restart all applications
    echo "🔄 Restarting PM2 applications..."
    run_safe_command "pm2 restart all" "PM2 applications restart"
else
    echo "🚀 Starting PM2 applications..."
    run_safe_command "pm2 start ecosystem.config.js" "PM2 applications start"
fi

# Save PM2 configuration
run_safe_command "pm2 save" "PM2 configuration save"

# 9. Test Application Endpoints
echo "🌐 Testing Application Endpoints..."
echo "==============================================="

# Wait a moment for services to start
sleep 10

# Test backend API
echo "🔍 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BACKEND_PORT/api/health" | grep -q "200"; then
    echo "✅ Backend API is responding"
else
    echo "❌ Backend API is not responding"
fi

# Test admin panel
echo "🔍 Testing admin panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ADMIN_PORT" | grep -q "200"; then
    echo "✅ Admin panel is responding"
else
    echo "❌ Admin panel is not responding"
fi

# Test user panel
echo "🔍 Testing user panel..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$USER_PORT" | grep -q "200"; then
    echo "✅ User panel is responding"
else
    echo "❌ User panel is not responding"
fi

# 10. Create System Monitoring Script
echo "📊 Creating System Monitoring Script..."
echo "==============================================="

cat > monitor-system.sh << 'EOF'
#!/bin/bash
# Win5x System Monitoring Script

echo "🔍 Win5x System Status Check"
echo "==============================================="
echo ""

echo "📊 Service Status:"
echo "• PostgreSQL: $(systemctl is-active postgresql)"
echo "• Redis: $(systemctl is-active redis-server)"
echo "• Nginx: $(systemctl is-active nginx)"
echo ""

echo "📊 PM2 Status:"
pm2 status
echo ""

echo "📊 Port Status:"
echo "• PostgreSQL (5432): $(netstat -tlnp | grep :5432 | wc -l) connections"
echo "• Redis (6379): $(netstat -tlnp | grep :6379 | wc -l) connections"
echo "• Nginx (80): $(netstat -tlnp | grep :80 | wc -l) connections"
echo "• Backend (8082): $(netstat -tlnp | grep :8082 | wc -l) connections"
echo "• Admin (8081): $(netstat -tlnp | grep :8081 | wc -l) connections"
echo "• User (8080): $(netstat -tlnp | grep :8080 | wc -l) connections"
echo ""

echo "📊 Disk Usage:"
df -h | grep -E "(Filesystem|/dev/)"
echo ""

echo "📊 Memory Usage:"
free -h
echo ""

echo "📊 Load Average:"
uptime
echo ""

echo "📊 Recent Logs (last 10 lines):"
echo "Backend Logs:"
tail -n 10 logs/backend-combined.log 2>/dev/null || echo "No backend logs found"
echo ""
echo "Admin Logs:"
tail -n 10 logs/admin-combined.log 2>/dev/null || echo "No admin logs found"
echo ""
echo "User Logs:"
tail -n 10 logs/user-combined.log 2>/dev/null || echo "No user logs found"
EOF

chmod +x monitor-system.sh

# 11. Create Backup Script
echo "💾 Creating Backup Script..."
echo "==============================================="

cat > backup-system.sh << 'EOF'
#!/bin/bash
# Win5x Backup Script

BACKUP_DIR="/var/backups/win5x"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="win5x_backup_$DATE.tar.gz"

echo "💾 Starting Win5x Backup..."
echo "Backup file: $BACKUP_FILE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='dist' \
    --exclude='logs' \
    --exclude='uploads' \
    --exclude='.git' \
    -C /var/www/kart .

# Database backup
pg_dump -h localhost -p 5432 -U win5x_user -d win5x_db > "$BACKUP_DIR/database_$DATE.sql"

echo "✅ Backup completed: $BACKUP_DIR/$BACKUP_FILE"
echo "✅ Database backup: $BACKUP_DIR/database_$DATE.sql"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "win5x_backup_*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "database_*.sql" -mtime +7 -delete

echo "🧹 Old backups cleaned up"
EOF

chmod +x backup-system.sh

# 12. Create Quick Restart Script
echo "🔄 Creating Quick Restart Script..."
echo "==============================================="

cat > quick-restart.sh << 'EOF'
#!/bin/bash
# Win5x Quick Restart Script

echo "🔄 Restarting Win5x Services..."

# Restart PM2 applications
echo "📋 Restarting PM2 applications..."
pm2 restart all

# Reload Nginx
echo "🌐 Reloading Nginx..."
sudo systemctl reload nginx

# Check status
echo "🔍 Checking service status..."
pm2 status
echo ""
echo "✅ Quick restart completed!"
EOF

chmod +x quick-restart.sh

# 13. Final Status Report
echo "📊 Final Status Report..."
echo "==============================================="

echo "🔍 Service Status:"
systemctl status postgresql --no-pager -l
echo ""
systemctl status redis-server --no-pager -l
echo ""
systemctl status nginx --no-pager -l
echo ""

echo "🔍 PM2 Status:"
pm2 status
echo ""

echo "🔍 Port Status:"
netstat -tlnp | grep -E ':(80|8080|8081|8082|5432|6379)'
echo ""

# Display final information
echo "==============================================="
echo "🎉 Win5x Server Initialization Complete!"
echo "==============================================="
echo ""
echo "📋 Initialization Summary:"
echo "• Services verified and running"
echo "• Database schema applied"
echo "• Admin user created/verified"
echo "• Applications built and started"
echo "• Endpoints tested"
echo "• Monitoring script created"
echo "• Backup script created"
echo "• Quick restart script created"
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
echo "• System Status: ./monitor-system.sh"
echo "• Create Backup: ./backup-system.sh"
echo "• Quick Restart: ./quick-restart.sh"
echo "• PM2 Status: pm2 status"
echo "• PM2 Logs: pm2 logs"
echo "• PM2 Restart: pm2 restart all"
echo "• Nginx Reload: sudo systemctl reload nginx"
echo ""
echo "📁 Project Location: $PROJECT_PATH"
echo "==============================================="
