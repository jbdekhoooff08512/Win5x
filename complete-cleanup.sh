#!/bin/bash

# Complete Server Cleanup Script for Win5x
# WARNING: This will delete EVERYTHING - PM2, Nginx, Database, Files, etc.
# Run this on server: ssh -p 6579 root@217.148.142.91

echo "⚠️  WARNING: This will delete EVERYTHING!"
echo "   - All PM2 processes"
echo "   - Nginx configuration"
echo "   - Database and data"
echo "   - All project files"
echo "   - Redis data"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🔥 Starting COMPLETE SERVER CLEANUP..."

# 1. Stop and delete all PM2 processes
echo "📦 Stopping and deleting all PM2 processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# 2. Stop and disable PM2 startup
echo "🚫 Disabling PM2 startup..."
pm2 unstartup 2>/dev/null || true

# 3. Stop Nginx
echo "🌐 Stopping Nginx..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true

# 4. Remove Nginx configuration
echo "🗑️ Removing Nginx configuration..."
rm -rf /etc/nginx/sites-available/win5x* 2>/dev/null || true
rm -rf /etc/nginx/sites-enabled/win5x* 2>/dev/null || true
rm -rf /etc/nginx/conf.d/win5x* 2>/dev/null || true

# 5. Stop and remove Redis
echo "🔴 Stopping and removing Redis..."
systemctl stop redis 2>/dev/null || true
systemctl disable redis 2>/dev/null || true
rm -rf /var/lib/redis 2>/dev/null || true
rm -rf /etc/redis 2>/dev/null || true

# 6. Stop PostgreSQL/MySQL (if exists)
echo "🗄️ Stopping database services..."
systemctl stop postgresql 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true
systemctl disable postgresql 2>/dev/null || true
systemctl disable mysql 2>/dev/null || true

# 7. Remove database data
echo "🗑️ Removing database data..."
rm -rf /var/lib/postgresql 2>/dev/null || true
rm -rf /var/lib/mysql 2>/dev/null || true

# 8. Remove project directory completely
echo "📁 Removing project directory..."
rm -rf /var/www/win5x 2>/dev/null || true
rm -rf /var/www/kart 2>/dev/null || true

# 9. Remove logs
echo "📝 Removing logs..."
rm -rf /var/log/win5x* 2>/dev/null || true
rm -rf /var/log/kart* 2>/dev/null || true
rm -rf /var/www/win5x/logs 2>/dev/null || true
rm -rf /var/www/kart/logs 2>/dev/null || true

# 10. Remove Node.js and PM2 globally (optional)
echo "📦 Removing Node.js and PM2..."
# Uncomment these lines if you want to remove Node.js completely
# apt-get remove -y nodejs npm 2>/dev/null || true
# npm uninstall -g pm2 2>/dev/null || true

# 11. Remove any remaining processes
echo "🔍 Killing any remaining processes..."
pkill -f "win5x" 2>/dev/null || true
pkill -f "kart" 2>/dev/null || true
pkill -f "node.*8080" 2>/dev/null || true
pkill -f "node.*8081" 2>/dev/null || true
pkill -f "node.*8082" 2>/dev/null || true

# 12. Clean up system
echo "🧹 Cleaning up system..."
apt-get autoremove -y 2>/dev/null || true
apt-get autoclean 2>/dev/null || true

# 13. Remove any cron jobs
echo "⏰ Removing cron jobs..."
crontab -r 2>/dev/null || true

# 14. Remove any systemd services
echo "🔧 Removing systemd services..."
rm -f /etc/systemd/system/win5x* 2>/dev/null || true
rm -f /etc/systemd/system/kart* 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true

echo ""
echo "✅ COMPLETE CLEANUP FINISHED!"
echo ""
echo "Everything has been removed:"
echo "   ✅ PM2 processes and configuration"
echo "   ✅ Nginx configuration"
echo "   ✅ Database services and data"
echo "   ✅ Redis data"
echo "   ✅ Project files"
echo "   ✅ Logs"
echo "   ✅ System cleanup"
echo ""
echo "Server is now completely clean and ready for fresh setup!"
echo ""
echo "To start fresh setup, run:"
echo "   git clone <your-repo-url> /var/www/win5x"
echo "   cd /var/www/win5x"
echo "   ./fresh-server-setup.sh"
