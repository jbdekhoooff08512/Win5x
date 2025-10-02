# Win5x Server Deployment Guide

## Current Issues Identified

Based on your terminal output, here are the main issues:

1. **PostgreSQL Connection Error**: `P1001: Can't reach database server at 217.148.142.91:5432`
2. **Missing PM2 Ecosystem Config**: `ecosystem.config.js` file not found
3. **PM2 Process Management**: No processes currently managed by PM2

## Quick Fix Commands

Run these commands on your server to fix the issues:

### 1. Upload Required Files
First, upload the `ecosystem.config.js` file to your server:

```bash
# From your local machine, upload the ecosystem config
scp -P 6579 ecosystem.config.js root@217.148.142.91:/var/www/kart/
```

### 2. Run Database Setup
```bash
# On the server, run the database setup script
cd /var/www/kart
chmod +x setup-database.sh
./setup-database.sh
```

### 3. Run Server Fix Script
```bash
# Run the comprehensive server fix script
chmod +x fix-server.sh
./fix-server.sh
```

## Manual Steps (if scripts don't work)

### Fix PostgreSQL Connection

1. **Check if PostgreSQL is running:**
```bash
systemctl status postgresql
```

2. **Start PostgreSQL if not running:**
```bash
systemctl start postgresql
systemctl enable postgresql
```

3. **Configure PostgreSQL to listen on all interfaces:**
```bash
# Edit postgresql.conf
nano /etc/postgresql/*/main/postgresql.conf
# Add or uncomment: listen_addresses = '*'

# Edit pg_hba.conf
nano /etc/postgresql/*/main/pg_hba.conf
# Add: host    all             all             0.0.0.0/0               md5

# Restart PostgreSQL
systemctl restart postgresql
```

4. **Create database and user:**
```bash
sudo -u postgres psql
CREATE DATABASE win5x;
CREATE USER win5x WITH PASSWORD 'win5x_password';
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x;
\q
```

### Setup PM2 Processes

1. **Install serve globally:**
```bash
npm install -g serve
```

2. **Create logs directory:**
```bash
mkdir -p /var/www/kart/logs
```

3. **Start PM2 processes:**
```bash
cd /var/www/kart
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Configure Nginx

1. **Create nginx configuration:**
```bash
cat > /etc/nginx/sites-available/win5x << 'EOF'
server {
    listen 80;
    server_name 217.148.142.91;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /admin {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

2. **Enable the site:**
```bash
ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## Verify Deployment

After running the fixes, verify everything is working:

```bash
# Check PM2 status
pm2 status

# Check PostgreSQL
systemctl status postgresql

# Check Nginx
systemctl status nginx

# Test database connection
cd /var/www/kart/packages/backend
pnpm prisma migrate deploy
```

## Application URLs

Once everything is running:
- **User Panel**: http://217.148.142.91
- **Admin Panel**: http://217.148.142.91/admin  
- **Backend API**: http://217.148.142.91/api

## Troubleshooting

### If PostgreSQL still won't connect:
1. Check firewall settings: `ufw status`
2. Verify PostgreSQL is listening: `netstat -tlnp | grep 5432`
3. Check logs: `journalctl -u postgresql -f`

### If PM2 processes fail:
1. Check logs: `pm2 logs`
2. Check individual process: `pm2 logs win5x-backend`
3. Restart specific process: `pm2 restart win5x-backend`

### If Nginx has issues:
1. Test configuration: `nginx -t`
2. Check logs: `tail -f /var/log/nginx/error.log`
3. Reload: `systemctl reload nginx`
