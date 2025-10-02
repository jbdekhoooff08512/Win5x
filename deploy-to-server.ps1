# Win5x Deployment Script
# This script will build and upload your project to the server

$SERVER = "217.148.142.91"
$PORT = "6579"
$USER = "root"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "   Win5x Deployment Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the project
Write-Host "📦 Step 1: Building project..." -ForegroundColor Yellow
try {
    pnpm build
    Write-Host "✅ Build successful!" -ForegroundColor Green
} catch {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Create deployment package
Write-Host ""
Write-Host "📦 Step 2: Creating deployment package..." -ForegroundColor Yellow
try {
    tar -czf win5x-deploy.tar.gz packages package.json pnpm-workspace.yaml pnpm-lock.yaml
    Write-Host "✅ Package created!" -ForegroundColor Green
} catch {
    Write-Host "❌ Package creation failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Upload to server
Write-Host ""
Write-Host "📤 Step 3: Uploading to server (you'll need to enter password)..." -ForegroundColor Yellow
scp -P $PORT win5x-deploy.tar.gz ${USER}@${SERVER}:/var/www/win5x/

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Upload successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Upload failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Deploy on server
Write-Host ""
Write-Host "🚀 Step 4: Deploying on server (you'll need to enter password again)..." -ForegroundColor Yellow

$deployScript = @'
cd /var/www/win5x
tar -xzf win5x-deploy.tar.gz
pnpm install --prod
pm2 reload ecosystem.config.js || pm2 start ecosystem.config.js
pm2 save
'@

ssh -p $PORT ${USER}@${SERVER} $deployScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item win5x-deploy.tar.gz -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Access your application:" -ForegroundColor Cyan
Write-Host "   User Panel:  http://217.148.142.91:8080" -ForegroundColor White
Write-Host "   Admin Panel: http://217.148.142.91:8080/admin" -ForegroundColor White
Write-Host "   Backend API: http://217.148.142.91:3001" -ForegroundColor White
Write-Host ""


