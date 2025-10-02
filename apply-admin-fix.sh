#!/bin/bash
# Apply Admin Panel Routing Fix
# This script applies the routing fixes and rebuilds the admin panel

echo "🔧 Applying Admin Panel Routing Fix..."
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

# 1. Stop PM2 applications
echo "🛑 Stopping PM2 Applications..."
echo "==============================================="

pm2 delete all 2>/dev/null || true

# 2. Rebuild admin panel with new configuration
echo "🔨 Rebuilding Admin Panel..."
echo "==============================================="

cd packages/admin
run_safe_command "pnpm run build" "Admin panel build"

# 3. Update Nginx configuration
echo "🔧 Updating Nginx Configuration..."
echo "==============================================="

cd ../..
run_safe_command "sudo cp nginx-win5x.conf /etc/nginx/sites-available/win5x" "Nginx config copy"
run_safe_command "sudo ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/" "Nginx site enable"
run_safe_command "sudo rm -f /etc/nginx/sites-enabled/default" "Default Nginx site removal"

# 4. Test Nginx configuration
echo "🔍 Testing Nginx Configuration..."
echo "==============================================="

run_safe_command "sudo nginx -t" "Nginx configuration test"

# 5. Start applications
echo "🚀 Starting Applications..."
echo "==============================================="

# Start user panel
run_safe_command "pm2 start serve --name win5x-user -- -s packages/user/dist -p 8080" "User panel start"

# Start backend
run_safe_command "pm2 start packages/backend/dist/server.js --name win5x-backend" "Backend start"

# Save PM2 configuration
run_safe_command "pm2 save" "PM2 configuration save"

# 6. Reload Nginx
echo "🔄 Reloading Nginx..."
echo "==============================================="

run_safe_command "sudo systemctl reload nginx" "Nginx reload"

# 7. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# 8. Test the fix
echo "🌐 Testing Admin Panel Access..."
echo "==============================================="

echo "🔍 Testing admin panel at /admin..."
if curl -s -o /dev/null -w "%{http_code}" "http://217.148.142.91/admin" | grep -q "200"; then
    echo "✅ Admin panel is accessible at /admin"
else
    echo "❌ Admin panel is not accessible at /admin"
fi

echo "🔍 Testing user panel at /..."
if curl -s -o /dev/null -w "%{http_code}" "http://217.148.142.91/" | grep -q "200"; then
    echo "✅ User panel is accessible at /"
else
    echo "❌ User panel is not accessible at /"
fi

# 9. Display final status
echo "📊 Final Status..."
echo "==============================================="

echo "🔍 PM2 Status:"
pm2 status

echo ""
echo "🔍 Access URLs:"
echo "• User Panel: http://217.148.142.91/"
echo "• Admin Panel: http://217.148.142.91/admin"
echo "• Backend API: http://217.148.142.91/api"

echo ""
echo "🔧 Changes Applied:"
echo "• Added base: '/admin/' to vite.config.ts"
echo "• Added basename='/admin' to React Router"
echo "• Updated Nginx to serve static files from /admin/"
echo "• Rebuilt admin panel with correct configuration"

echo ""
echo "==============================================="
echo "🎉 Admin Panel Routing Fix Applied!"
echo "==============================================="
