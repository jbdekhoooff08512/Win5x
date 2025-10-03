# Win5x Backend Build Script for Windows PowerShell

Write-Host "🚀 Starting Win5x Backend Build Process..." -ForegroundColor Green
Write-Host ""

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path "./dist") {
    Remove-Item -Recurse -Force "./dist"
}
if (Test-Path "./build") {
    Remove-Item -Recurse -Force "./build"
}

# Compile TypeScript
Write-Host "📦 Compiling TypeScript..." -ForegroundColor Yellow
try {
    npx tsc
    Write-Host "✅ TypeScript compilation successful" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ TypeScript compilation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create build directory structure
Write-Host "📁 Creating build directory structure..." -ForegroundColor Yellow
$buildDir = "./build"
$distDir = "./dist"

# Create main build directory
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

# Copy dist folder to build/dist
Write-Host "📋 Copying compiled files to build/dist..." -ForegroundColor Yellow
Copy-Item -Recurse -Force $distDir "$buildDir/dist"

# Copy essential files
Write-Host "📋 Copying essential files..." -ForegroundColor Yellow
$filesToCopy = @(
    "package.json",
    "prisma/schema.prisma",
    "prisma/migrations"
)

foreach ($file in $filesToCopy) {
    $srcPath = Join-Path "." $file
    $destPath = Join-Path $buildDir $file
    
    if (Test-Path $srcPath) {
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        if ((Get-Item $srcPath) -is [System.IO.DirectoryInfo]) {
            Copy-Item -Recurse -Force $srcPath $destPath
        } else {
            Copy-Item -Force $srcPath $destPath
        }
        Write-Host "  ✓ Copied $file" -ForegroundColor Green
    }
}

# Copy uploads directory if it exists
if (Test-Path "./uploads") {
    Write-Host "📋 Copying uploads directory..." -ForegroundColor Yellow
    Copy-Item -Recurse -Force "./uploads" "$buildDir/uploads"
}

# Create production package.json
Write-Host "📝 Creating production package.json..." -ForegroundColor Yellow
$packageJson = Get-Content "./package.json" | ConvertFrom-Json

# Remove devDependencies and scripts not needed in production
$productionPackageJson = @{
    name = $packageJson.name
    version = $packageJson.version
    description = $packageJson.description
    main = $packageJson.main
    scripts = @{
        start = "node dist/server.js"
        "db:migrate" = "prisma migrate deploy"
        "db:generate" = "prisma generate"
    }
    dependencies = $packageJson.dependencies
}

$productionPackageJson | ConvertTo-Json -Depth 10 | Set-Content "$buildDir/package.json"

# Create .env.example
Write-Host "📝 Creating .env.example..." -ForegroundColor Yellow
$envExample = @"
# Database
DATABASE_URL="postgresql://username:password@localhost:5432/win5x_db"

# JWT
JWT_SECRET="your-super-secret-jwt-key-here"
JWT_EXPIRES_IN="7d"

# Redis
REDIS_URL="redis://localhost:6379"

# Server
PORT=3001
NODE_ENV=production

# CORS
CORS_ORIGIN="http://localhost:3000"

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_PATH="./uploads"

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Game Settings
MIN_BET_AMOUNT=1
MAX_BET_AMOUNT=10000
GAME_DURATION=30000
"@

Set-Content "$buildDir/.env.example" $envExample

# Create README for build
Write-Host "📝 Creating build README..." -ForegroundColor Yellow
$buildReadme = @"
# Win5x Backend Build

This is the production build of the Win5x backend server.

## Structure

- `dist/` - Compiled TypeScript files
- `prisma/` - Database schema and migrations
- `uploads/` - File uploads directory
- `package.json` - Production dependencies
- `.env.example` - Environment variables template

## Setup

1. Copy `.env.example` to `.env` and configure your environment variables
2. Install dependencies: `npm install`
3. Generate Prisma client: `npm run db:generate`
4. Run migrations: `npm run db:migrate`
5. Start the server: `npm start`

## Environment Variables

See `.env.example` for all required environment variables.

## Production Notes

- Make sure Redis is running
- Ensure PostgreSQL database is accessible
- Configure proper CORS origins
- Set up proper logging and monitoring
- Use HTTPS in production
"@

Set-Content "$buildDir/README.md" $buildReadme

Write-Host ""
Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
Write-Host "📦 Build output: $(Resolve-Path $buildDir)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the build folder to your production server" -ForegroundColor White
Write-Host "2. Copy .env.example to .env and configure your environment" -ForegroundColor White
Write-Host "3. Run: npm install && npm run db:generate && npm run db:migrate && npm start" -ForegroundColor White
