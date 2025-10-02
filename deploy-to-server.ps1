# Win5x Server Deployment Script
# This script will deploy directly to server

$SERVER = "217.148.142.91"
$PORT = "6579"
$USER = "root"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "   Win5x Server Deployment" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Deploy directly on server
Write-Host "🚀 Deploying to server..." -ForegroundColor Yellow

$deployScript = @'
echo "========================================="
echo "    Win5x Server Deployment"
echo "========================================="
echo

cd /var/www/kart
echo "📝 Step 1: Pulling latest changes from Git..."
git pull origin main
echo "✅ Git pull completed!"
echo

echo "📦 Step 2: Installing dependencies..."
pnpm install --prod
echo "✅ Dependencies installed!"
echo

echo "🗄️ Step 3: Updating database..."
cd packages/backend
pnpm prisma generate
pnpm prisma migrate deploy
echo "✅ Database updated!"
echo

echo "🔨 Step 4: Building project..."
cd /var/www/kart
pnpm run build
echo "✅ Build completed!"
echo

echo "🔄 Step 5: Restarting services..."
# Copy ecosystem config if it doesn't exist
if [ ! -f ecosystem.config.js ]; then
    echo "⚠️ ecosystem.config.js not found. Please upload it to the server."
    echo "You can copy it from your local project directory."
fi

pm2 restart ecosystem.config.js || pm2 start ecosystem.config.js
pm2 save
echo "✅ PM2 services restarted!"
echo

echo "🌐 Step 6: Reloading Nginx..."
nginx -t && systemctl reload nginx
echo "✅ Nginx reloaded!"
echo

echo "========================================="
echo "✅ Deployment completed successfully!"
echo "========================================="
echo
echo "🌐 Application URLs:"
echo "   User Panel:  http://217.148.142.91:8080"
echo "   Admin Panel: http://217.148.142.91:8080/admin"
echo "   Backend API: http://217.148.142.91:3001"
echo
echo "📊 Service Status:"
pm2 status
echo
'@

ssh -p $PORT ${USER}@${SERVER} $deployScript

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "✅ Server Deployment Complete!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Red
    Write-Host "❌ Deployment Failed!" -ForegroundColor Red
    Write-Host "================================" -ForegroundColor Red
    Write-Host "Check server logs for more details." -ForegroundColor Yellow
    exit 1
}

