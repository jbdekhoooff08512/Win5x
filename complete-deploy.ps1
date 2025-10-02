# Complete Win5x Deployment Script
# This does everything automatically!

$SERVER = "217.148.142.91"
$PORT = "6579"
$USER = "root"

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   Win5x Complete Deployment" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build project
Write-Host "📦 Step 1/5: Building project..." -ForegroundColor Yellow
pnpm build
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Create deployment package
Write-Host ""
Write-Host "📦 Step 2/5: Creating deployment package..." -ForegroundColor Yellow
tar -czf win5x-deploy.tar.gz packages package.json pnpm-workspace.yaml pnpm-lock.yaml
Write-Host "✅ Package created!" -ForegroundColor Green

# Step 3: Upload scripts to server
Write-Host ""
Write-Host "📤 Step 3/5: Uploading to server..." -ForegroundColor Yellow
Write-Host "(You'll need to enter your password 2-3 times)" -ForegroundColor Gray

scp -P $PORT quick-deploy.sh ${USER}@${SERVER}:/root/
scp -P $PORT setup-and-deploy.sh ${USER}@${SERVER}:/root/
scp -P $PORT win5x-deploy.tar.gz ${USER}@${SERVER}:/root/

Write-Host "✅ Files uploaded!" -ForegroundColor Green

# Step 4: Run server setup
Write-Host ""
Write-Host "🔧 Step 4/5: Setting up server (this may take 2-3 minutes)..." -ForegroundColor Yellow
ssh -p $PORT ${USER}@${SERVER} "bash /root/quick-deploy.sh"

Write-Host "✅ Server configured!" -ForegroundColor Green

# Step 5: Deploy application
Write-Host ""
Write-Host "🚀 Step 5/5: Deploying application..." -ForegroundColor Yellow
ssh -p $PORT ${USER}@${SERVER} "bash /root/setup-and-deploy.sh"

# Cleanup local file
Remove-Item win5x-deploy.tar.gz -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Your application is now live at:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   User Panel:  " -NoNewline -ForegroundColor White
Write-Host "http://217.148.142.91:8080" -ForegroundColor Green
Write-Host "   Admin Panel: " -NoNewline -ForegroundColor White
Write-Host "http://217.148.142.91:8080/admin" -ForegroundColor Green
Write-Host "   Backend API: " -NoNewline -ForegroundColor White
Write-Host "http://217.148.142.91:3001" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Default Admin Login:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: Admin123!" -ForegroundColor White
Write-Host ""
Write-Host "📊 Check status: " -NoNewline -ForegroundColor Cyan
Write-Host "ssh -p 6579 root@217.148.142.91 'pm2 status'" -ForegroundColor White
Write-Host "📋 View logs:    " -NoNewline -ForegroundColor Cyan
Write-Host "ssh -p 6579 root@217.148.142.91 'pm2 logs'" -ForegroundColor White
Write-Host ""


