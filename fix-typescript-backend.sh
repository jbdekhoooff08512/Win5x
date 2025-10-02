#!/bin/bash

# Fix TypeScript and Backend Build Issues
echo "========================================="
echo "    Fix TypeScript and Backend Issues"
echo "========================================="
echo

cd /var/www/kart

echo "🔧 Step 1: Installing TypeScript globally..."
npm install -g typescript
echo "✅ TypeScript installed globally"
echo

echo "🔧 Step 2: Installing development dependencies..."
pnpm install
echo "✅ Development dependencies installed"
echo

echo "🔧 Step 3: Checking if backend dist exists..."
if [ -d "packages/backend/dist" ]; then
    echo "✅ Backend dist directory exists"
    ls -la packages/backend/dist/
else
    echo "❌ Backend dist directory missing"
fi
echo

echo "🔧 Step 4: Building backend specifically..."
cd packages/backend
echo "Current directory: $(pwd)"
echo "Checking package.json..."
cat package.json | grep -A 5 -B 5 "build"

echo "Running backend build..."
pnpm run build
echo "✅ Backend build completed"
echo

echo "🔧 Step 5: Verifying backend build..."
if [ -f "dist/server.js" ]; then
    echo "✅ Backend dist/server.js exists"
    ls -la dist/
else
    echo "❌ Backend dist/server.js still missing"
    echo "Checking what files exist in dist/:"
    ls -la dist/ 2>/dev/null || echo "No dist directory"
fi
echo

cd /var/www/kart

echo "🔧 Step 6: Building all packages..."
pnpm run build
echo "✅ All packages built"
echo

echo "🔧 Step 7: Checking all dist directories..."
echo "Backend dist:"
ls -la packages/backend/dist/ 2>/dev/null || echo "Backend dist missing"

echo "Admin dist:"
ls -la packages/admin/dist/ 2>/dev/null || echo "Admin dist missing"

echo "User dist:"
ls -la packages/user/dist/ 2>/dev/null || echo "User dist missing"
echo

echo "🔧 Step 8: Stopping all services and fixing ports..."
pm2 delete all 2>/dev/null || true
pkill -f "serve.*packages" 2>/dev/null || true

# Check what's using port 8080
echo "Checking what's using port 8080:"
netstat -tlnp | grep :8080 || echo "Port 8080 is free"
echo

echo "🔧 Step 9: Starting services with correct configuration..."

# Update ecosystem config to use different ports if needed
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/dist/server.js',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-admin',
      script: 'serve',
      args: '-s packages/admin/dist -l 8081',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      log_file: './logs/admin-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-user',
      script: 'serve',
      args: '-s packages/user/dist -l 8082',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/user-error.log',
      out_file: './logs/user-out.log',
      log_file: './logs/user-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
EOF

echo "✅ Ecosystem config updated (user frontend now on port 8082)"
echo

echo "🔧 Step 10: Starting PM2 services..."
pm2 start ecosystem.config.js
pm2 save
echo "✅ PM2 services started"
echo

echo "🔧 Step 11: Checking service status..."
sleep 3
pm2 status
echo

echo "🔧 Step 12: Checking if services are listening..."
echo "Backend (port 3001):"
netstat -tlnp | grep :3001 || echo "❌ Backend not listening"

echo "Admin frontend (port 8081):"
netstat -tlnp | grep :8081 || echo "❌ Admin not listening"

echo "User frontend (port 8082):"
netstat -tlnp | grep :8082 || echo "❌ User not listening"
echo

echo "🔧 Step 13: Updating Nginx configuration..."
cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 80;
    server_name 217.148.142.91;

    # User frontend
    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Admin panel
    location /admin {
        proxy_pass http://localhost:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Test and reload nginx
nginx -t && systemctl reload nginx
echo "✅ Nginx configuration updated"
echo

echo "🔧 Step 14: Testing all endpoints..."
echo "Testing backend API:"
curl -s -I http://localhost:3001/ | head -1 || echo "❌ Backend not responding"

echo "Testing user frontend:"
curl -s -I http://localhost:8082/ | head -1 || echo "❌ User frontend not responding"

echo "Testing admin frontend:"
curl -s -I http://localhost:8081/ | head -1 || echo "❌ Admin frontend not responding"
echo

echo "🔧 Step 15: Testing through Nginx..."
echo "Testing main site:"
curl -s -I http://localhost/ | head -1 || echo "❌ Main site not responding"

echo "Testing admin panel:"
curl -s -I http://localhost/admin/ | head -1 || echo "❌ Admin panel not responding"

echo "Testing API:"
curl -s -I http://localhost/api/ | head -1 || echo "❌ API not responding"
echo

echo "========================================="
echo "✅ TypeScript and Backend fix completed!"
echo "========================================="
echo
echo "🌐 Your application should now be accessible at:"
echo "   Main Site: http://217.148.142.91"
echo "   Admin Panel: http://217.148.142.91/admin"
echo "   API: http://217.148.142.91/api"
echo
echo "📊 Service Status:"
pm2 status
echo
echo "📝 If backend still fails, check logs:"
echo "   pm2 logs win5x-backend"
echo "   tail -f /var/www/kart/logs/backend-error.log"
echo
