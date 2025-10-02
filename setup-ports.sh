#!/bin/bash

# Win5x Port Setup Script
# Sets up proper port configuration: 8080 user, 8081 admin, 8082 backend

echo "========================================="
echo "    Win5x Port Setup Script"
echo "========================================="
echo

cd /var/www/kart

echo "🔧 Step 1: Stopping all services..."
pm2 delete all 2>/dev/null || true
pkill -f "serve.*packages" 2>/dev/null || true
echo "✅ All services stopped"
echo

echo "🔧 Step 2: Updating ecosystem configuration..."
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
        PORT: 8082
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
      args: '-s packages/user/dist -l 8080',
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
echo "✅ Ecosystem configuration updated"
echo

echo "🔧 Step 3: Updating Nginx configuration..."
cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 80;
    server_name 217.148.142.91;

    # User frontend - Port 8080
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Admin panel - Port 8081
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

    # Backend API - Port 8082
    location /api {
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
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/

# Test and reload nginx
nginx -t && systemctl reload nginx
echo "✅ Nginx configuration updated"
echo

echo "🔧 Step 4: Creating logs directory..."
mkdir -p logs
echo "✅ Logs directory created"
echo

echo "🔧 Step 5: Starting PM2 services..."
pm2 start ecosystem.config.js
pm2 save
echo "✅ PM2 services started"
echo

echo "🔧 Step 6: Checking service status..."
sleep 3
pm2 status
echo

echo "🔧 Step 7: Verifying port configuration..."
echo "Backend (port 8082):"
netstat -tlnp | grep :8082 || echo "❌ Backend not listening"

echo "Admin frontend (port 8081):"
netstat -tlnp | grep :8081 || echo "❌ Admin not listening"

echo "User frontend (port 8080):"
netstat -tlnp | grep :8080 || echo "❌ User not listening"
echo

echo "🔧 Step 8: Testing endpoints..."
echo "Testing backend API (port 8082):"
curl -s -I http://localhost:8082/ | head -1 || echo "❌ Backend not responding"

echo "Testing user frontend (port 8080):"
curl -s -I http://localhost:8080/ | head -1 || echo "❌ User frontend not responding"

echo "Testing admin frontend (port 8081):"
curl -s -I http://localhost:8081/ | head -1 || echo "❌ Admin frontend not responding"
echo

echo "🔧 Step 9: Testing through Nginx..."
echo "Testing main site:"
curl -s -I http://localhost/ | head -1 || echo "❌ Main site not responding"

echo "Testing admin panel:"
curl -s -I http://localhost/admin/ | head -1 || echo "❌ Admin panel not responding"

echo "Testing API:"
curl -s -I http://localhost/api/ | head -1 || echo "❌ API not responding"
echo

echo "========================================="
echo "✅ Port setup completed!"
echo "========================================="
echo
echo "🌐 Port Configuration:"
echo "   User Frontend: Port 8080"
echo "   Admin Panel:   Port 8081"
echo "   Backend API:   Port 8082"
echo
echo "🌐 Application URLs:"
echo "   Main Site: http://217.148.142.91"
echo "   Admin Panel: http://217.148.142.91/admin"
echo "   API: http://217.148.142.91/api"
echo
echo "📊 To monitor services:"
echo "   pm2 status"
echo "   pm2 logs"
echo
