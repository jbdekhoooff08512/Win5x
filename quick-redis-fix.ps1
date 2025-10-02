# Quick Redis Fix Script for Windows PowerShell
# This script fixes the Redis authentication issue for development

Write-Host "🔧 Quick Redis Fix for Development..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Navigate to backend directory
Set-Location packages/backend
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cannot navigate to backend directory" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Working in backend directory" -ForegroundColor Yellow

# Create .env file with correct Redis URL (no password)
Write-Host "🔧 Creating Backend .env File..." -ForegroundColor Blue
$envContent = @"
# Database
DATABASE_URL="postgresql://win5x_user:Win5xDB@2024@localhost:5432/win5x_db"

# JWT
JWT_SECRET="8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4"
JWT_EXPIRES_IN="24h"

# Redis (NO PASSWORD for development)
REDIS_URL="redis://localhost:6379"

# Server
PORT=3001
NODE_ENV=development

# Admin credentials
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@win5x.com"
ADMIN_PASSWORD="Admin@123"

# Security
BCRYPT_ROUNDS=12

# File uploads
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880

# Game settings
GAME_BETTING_DURATION=30
GAME_SPIN_DURATION=10
GAME_RESULT_DURATION=15

# Payment settings
USDT_TO_INR_RATE=83.0
DEPOSIT_BONUS_PERCENTAGE=5

# Referral settings
REFERRAL_LEVEL1_PERCENTAGE=5
REFERRAL_LEVEL2_PERCENTAGE=3
REFERRAL_LEVEL3_PERCENTAGE=1

# Attendance
ATTENDANCE_DAY7_AMOUNT=60
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Backend .env created with Redis URL: redis://localhost:6379" -ForegroundColor Green

# Create admin .env
Set-Location ../admin
$adminEnvContent = @"
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
"@

$adminEnvContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Admin .env created" -ForegroundColor Green

# Create user .env
Set-Location ../user
$userEnvContent = @"
VITE_API_URL=http://localhost:3001
VITE_SOCKET_URL=http://localhost:3001
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
"@

$userEnvContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ User .env created" -ForegroundColor Green

# Go back to root
Set-Location ../..

Write-Host ""
Write-Host "📊 Environment Files Created:" -ForegroundColor Yellow
Write-Host "• Backend: packages/backend/.env" -ForegroundColor White
Write-Host "• Admin: packages/admin/.env" -ForegroundColor White
Write-Host "• User: packages/user/.env" -ForegroundColor White

Write-Host ""
Write-Host "🌐 Development URLs:" -ForegroundColor Yellow
Write-Host "• Backend API: http://localhost:3001" -ForegroundColor White
Write-Host "• Admin Panel: http://localhost:3000/admin/" -ForegroundColor White
Write-Host "• User Panel: http://localhost:3002/" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Stop current development server (Ctrl+C)" -ForegroundColor White
Write-Host "2. Run: pnpm run dev" -ForegroundColor White
Write-Host "3. Redis should work without authentication errors" -ForegroundColor White

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "🎉 Redis Fix Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

