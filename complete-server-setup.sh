#!/bin/bash

# Win5x Complete Server Setup and Run Script
# This script checks everything and runs the server properly

echo "========================================="
echo "    Win5x Complete Server Setup"
echo "========================================="
echo

cd /var/www/kart

echo "🔍 Step 1: Checking Git status and resolving conflicts..."
if git status --porcelain | grep -q .; then
    echo "⚠️ Local changes detected. Stashing them..."
    git stash
    echo "✅ Local changes stashed"
fi

echo "📥 Pulling latest changes..."
git pull origin main
echo "✅ Git pull completed"
echo

echo "🔍 Step 2: Checking system requirements..."
echo "Checking Node.js version:"
node --version || echo "❌ Node.js not installed"

echo "Checking pnpm version:"
pnpm --version || echo "❌ pnpm not installed"

echo "Checking TypeScript:"
tsc --version || echo "⚠️ TypeScript not installed globally"

echo "Checking serve:"
serve --version || echo "⚠️ serve not installed globally"

echo "Checking PM2:"
pm2 --version || echo "❌ PM2 not installed"

echo "Checking PostgreSQL:"
systemctl is-active postgresql || echo "⚠️ PostgreSQL not running"
echo

echo "🔧 Step 3: Installing missing dependencies..."
echo "Installing TypeScript globally..."
npm install -g typescript

echo "Installing serve globally..."
npm install -g serve

echo "Installing PM2 globally..."
npm install -g pm2

echo "Installing project dependencies..."
pnpm install
echo "✅ Dependencies installed"
echo

echo "🔍 Step 4: Checking PostgreSQL status..."
if ! systemctl is-active --quiet postgresql; then
    echo "⚠️ PostgreSQL not running. Starting it..."
    systemctl start postgresql
    systemctl enable postgresql
    echo "✅ PostgreSQL started and enabled"
fi

# Check if PostgreSQL is listening on the correct port
if ! netstat -tlnp | grep -q ":5432"; then
    echo "⚠️ PostgreSQL not listening on port 5432"
    echo "Configuring PostgreSQL..."
    
    # Update postgresql.conf to listen on all addresses
    if ! grep -q "listen_addresses = '*'" /etc/postgresql/*/main/postgresql.conf; then
        echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
    fi
    
    # Update pg_hba.conf to allow connections
    if ! grep -q "host    all             all             0.0.0.0/0               md5" /etc/postgresql/*/main/pg_hba.conf; then
        echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/*/main/pg_hba.conf
    fi
    
    systemctl restart postgresql
    echo "✅ PostgreSQL configured and restarted"
fi

echo "✅ PostgreSQL check completed"
echo

echo "🔍 Step 5: Checking database connection..."
cd packages/backend
if pnpm prisma migrate deploy; then
    echo "✅ Database connection successful"
else
    echo "⚠️ Database connection failed. Creating database and user..."
    
    # Create database and user
    sudo -u postgres psql << 'EOF'
-- Create database if it doesn't exist
SELECT 'CREATE DATABASE win5x'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'win5x')\gexec

-- Create user if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'win5x') THEN

      CREATE ROLE win5x LOGIN PASSWORD 'win5x_password';
   END IF;
END
$do$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x;
ALTER USER win5x CREATEDB;

\q
EOF
    
    # Try migration again
    if pnpm prisma migrate deploy; then
        echo "✅ Database setup completed"
    else
        echo "❌ Database setup failed. Please check your .env file"
    fi
fi

cd /var/www/kart
echo

echo "🔍 Step 6: Checking build files..."
echo "Checking backend build:"
if [ -d "packages/backend/dist" ] && [ -f "packages/backend/dist/server.js" ]; then
    echo "✅ Backend build exists"
else
    echo "⚠️ Backend build missing. Building..."
    cd packages/backend
    pnpm run build
    cd /var/www/kart
fi

echo "Checking admin build:"
if [ -d "packages/admin/dist" ]; then
    echo "✅ Admin build exists"
else
    echo "⚠️ Admin build missing. Building..."
    cd packages/admin
    pnpm run build
    cd /var/www/kart
fi

echo "Checking user build:"
if [ -d "packages/user/dist" ]; then
    echo "✅ User build exists"
else
    echo "⚠️ User build missing. Building..."
    cd packages/user
    pnpm run build
    cd /var/www/kart
fi

echo "✅ Build check completed"
echo

echo "🔧 Step 7: Stopping existing services..."
pm2 delete all 2>/dev/null || true
pkill -f "serve.*packages" 2>/dev/null || true
echo "✅ Existing services stopped"
echo

echo "🔧 Step 8: Creating logs directory..."
mkdir -p logs
echo "✅ Logs directory created"
echo

echo "🔧 Step 9: Setting up ecosystem configuration..."
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
echo "✅ Ecosystem configuration created"
echo

echo "🔧 Step 10: Starting PM2 services..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup
echo "✅ PM2 services started"
echo

echo "🔧 Step 11: Setting up Nginx configuration..."
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

echo "🔍 Step 12: Waiting for services to start..."
sleep 5
echo

echo "🔍 Step 13: Checking service status..."
echo "PM2 Status:"
pm2 status
echo

echo "🔍 Step 14: Checking if services are listening..."
echo "Backend (port 8082):"
netstat -tlnp | grep :8082 || echo "❌ Backend not listening"

echo "Admin frontend (port 8081):"
netstat -tlnp | grep :8081 || echo "❌ Admin not listening"

echo "User frontend (port 8080):"
netstat -tlnp | grep :8080 || echo "❌ User not listening"
echo

echo "🔍 Step 15: Testing service endpoints..."
echo "Testing backend API:"
curl -s -I http://localhost:8082/ | head -1 || echo "❌ Backend not responding"

echo "Testing user frontend:"
curl -s -I http://localhost:8080/ | head -1 || echo "❌ User frontend not responding"

echo "Testing admin frontend:"
curl -s -I http://localhost:8081/ | head -1 || echo "❌ Admin frontend not responding"
echo

echo "🔍 Step 16: Testing through Nginx..."
echo "Testing main site:"
curl -s -I http://localhost/ | head -1 || echo "❌ Main site not responding"

echo "Testing admin panel:"
curl -s -I http://localhost/admin/ | head -1 || echo "❌ Admin panel not responding"

echo "Testing API:"
curl -s -I http://localhost/api/ | head -1 || echo "❌ API not responding"
echo

echo "🔍 Step 17: Checking system resources..."
echo "Memory usage:"
free -h
echo

echo "Disk usage:"
df -h /
echo

echo "CPU usage:"
top -bn1 | grep "Cpu(s)" || echo "CPU info not available"
echo

echo "========================================="
echo "✅ Complete server setup finished!"
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
echo "📊 Service Management:"
echo "   Check status: pm2 status"
echo "   View logs: pm2 logs"
echo "   Restart all: pm2 restart all"
echo "   Stop all: pm2 stop all"
echo
echo "📝 Log Files:"
echo "   Backend: tail -f /var/www/kart/logs/backend-error.log"
echo "   Admin: tail -f /var/www/kart/logs/admin-error.log"
echo "   User: tail -f /var/www/kart/logs/user-error.log"
echo "   Nginx: tail -f /var/log/nginx/error.log"
echo
echo "🔧 Troubleshooting:"
echo "   If services fail: pm2 logs [service-name]"
echo "   If database issues: systemctl status postgresql"
echo "   If nginx issues: nginx -t && systemctl status nginx"
echo
