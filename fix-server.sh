#!/bin/bash

# Win5x Server Setup and Fix Script
# This script will fix common deployment issues

echo "========================================="
echo "    Win5x Server Setup & Fix Script"
echo "========================================="
echo

# Change to project directory
cd /var/www/kart

echo "🔧 Step 1: Installing missing dependencies..."
# Install serve globally if not already installed
npm install -g serve

echo "✅ Dependencies installed!"
echo

echo "🗄️ Step 2: Checking PostgreSQL status..."
# Check if PostgreSQL is running
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL is running"
else
    echo "⚠️ PostgreSQL is not running. Starting it..."
    systemctl start postgresql
    systemctl enable postgresql
    echo "✅ PostgreSQL started and enabled"
fi

# Check if PostgreSQL is listening on the correct port
if netstat -tlnp | grep -q ":5432"; then
    echo "✅ PostgreSQL is listening on port 5432"
else
    echo "⚠️ PostgreSQL is not listening on port 5432"
    echo "Checking PostgreSQL configuration..."
    
    # Check if PostgreSQL is configured to listen on all interfaces
    if ! grep -q "listen_addresses = '*'" /etc/postgresql/*/main/postgresql.conf; then
        echo "🔧 Configuring PostgreSQL to listen on all interfaces..."
        echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
        systemctl restart postgresql
        echo "✅ PostgreSQL configuration updated"
    fi
fi

echo "✅ Database check completed!"
echo

echo "🔨 Step 3: Building project..."
pnpm run build
echo "✅ Build completed!"
echo

echo "📁 Step 4: Creating logs directory..."
mkdir -p logs
echo "✅ Logs directory created!"
echo

echo "🔄 Step 5: Setting up PM2 processes..."
# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start all services using ecosystem config
pm2 start ecosystem.config.js
pm2 save
pm2 startup

echo "✅ PM2 services started!"
echo

echo "🌐 Step 6: Configuring Nginx..."
# Create nginx configuration if it doesn't exist
if [ ! -f /etc/nginx/sites-available/win5x ]; then
    cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 80;
    server_name 217.148.142.91;

    # User frontend
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

    # Enable the site
    ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    nginx -t && systemctl reload nginx
    echo "✅ Nginx configuration created and reloaded!"
else
    echo "✅ Nginx configuration already exists"
    nginx -t && systemctl reload nginx
fi

echo "✅ Nginx configured!"
echo

echo "📊 Step 7: Checking service status..."
echo "PM2 Status:"
pm2 status
echo

echo "PostgreSQL Status:"
systemctl status postgresql --no-pager -l
echo

echo "Nginx Status:"
systemctl status nginx --no-pager -l
echo

echo "========================================="
echo "✅ Server setup completed successfully!"
echo "========================================="
echo
echo "🌐 Application URLs:"
echo "   User Panel:  http://217.148.142.91"
echo "   Admin Panel: http://217.148.142.91/admin"
echo "   Backend API: http://217.148.142.91/api"
echo
echo "📊 To check service status:"
echo "   pm2 status"
echo "   systemctl status postgresql"
echo "   systemctl status nginx"
echo
echo "📝 To view logs:"
echo "   pm2 logs"
echo "   tail -f /var/www/kart/logs/*.log"
echo
