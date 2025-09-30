# Win5x Setup Script for PowerShell
Write-Host "Setting up Win5x Casino Game..." -ForegroundColor Cyan

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check prerequisites
Write-Status "Checking prerequisites..."

# Check Node.js
try {
    $nodeVersion = node --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Node.js is not installed. Please install Node.js 18+ and try again."
        exit 1
    }
    Write-Status "Node.js version: $nodeVersion"
} catch {
    Write-Error "Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
}

# Check Node.js version
$nodeMajorVersion = (node --version).Split('v')[1].Split('.')[0]
if ([int]$nodeMajorVersion -lt 18) {
    Write-Error "Node.js version 18+ is required. Current version: $(node --version)"
    exit 1
}

# Check PNPM
try {
    $pnpmVersion = pnpm --version
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "PNPM is not installed. Installing PNPM..."
        npm install -g pnpm
    } else {
        Write-Status "PNPM version: $pnpmVersion"
    }
} catch {
    Write-Warning "PNPM is not installed. Installing PNPM..."
    npm install -g pnpm
}

# Check PostgreSQL
try {
    $psqlVersion = psql --version
    if ($LASTEXITCODE -eq 0) {
        Write-Status "PostgreSQL version: $psqlVersion"
    } else {
        Write-Warning "PostgreSQL is not installed. Please install PostgreSQL 13+ manually."
        Write-Warning "Windows: Download from https://www.postgresql.org/download/"
    }
} catch {
    Write-Warning "PostgreSQL is not installed. Please install PostgreSQL 13+ manually."
    Write-Warning "Windows: Download from https://www.postgresql.org/download/"
}

# Check Redis
try {
    $redisVersion = redis-cli --version
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Redis version: $redisVersion"
    } else {
        Write-Warning "Redis is not installed. Please install Redis 6+ manually."
        Write-Warning "Windows: Download from https://redis.io/download"
    }
} catch {
    Write-Warning "Redis is not installed. Please install Redis 6+ manually."
    Write-Warning "Windows: Download from https://redis.io/download"
}

Write-Status "Prerequisites check completed."

# Install dependencies
Write-Status "Installing dependencies..."
pnpm install

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install dependencies. Please check your package manager setup."
    exit 1
}

# Setup environment
Write-Status "Setting up environment..."
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Warning "Created .env file from template. Please update it with your database credentials."
    } else {
        Write-Warning "No .env.example file found. Please create .env file manually."
    }
} else {
    Write-Status ".env file already exists."
}

if (-not (Test-Path "packages/backend/.env")) {
    if (Test-Path "packages/backend/.env.example") {
        Copy-Item "packages/backend/.env.example" "packages/backend/.env"
        Write-Warning "Created backend .env file from template. Please update it with your credentials."
    } else {
        Write-Warning "No backend .env.example file found. Please create packages/backend/.env file manually."
    }
} else {
    Write-Status "Backend .env file already exists."
}

# Build common package first
Write-Status "Building shared packages..."
pnpm --filter common build

# Setup database
Write-Status "Setting up database..."
Push-Location "packages/backend"

# Generate Prisma client
Write-Status "Generating Prisma client..."
pnpm db:generate

# Check if database is accessible
Write-Status "Checking database connection..."
try {
    pnpm exec prisma db push --accept-data-loss
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Database schema updated successfully."
        
        # Seed database
        Write-Status "Seeding database with initial data..."
        pnpm db:seed
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Database seeded successfully."
        } else {
            Write-Warning "Database seeding failed. You may need to run 'pnpm db:seed' manually later."
        }
    } else {
        Write-Error "Failed to connect to database. Please check your DATABASE_URL in .env file."
        Write-Warning "Make sure PostgreSQL is running and the database exists."
        Pop-Location
        exit 1
    }
} catch {
    Write-Error "Failed to connect to database. Please check your DATABASE_URL in .env file."
    Write-Warning "Make sure PostgreSQL is running and the database exists."
    Pop-Location
    exit 1
}

Pop-Location

Write-Status "Setup completed successfully!"
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor $Blue
Write-Host "1. Update .env files with your database and Redis URLs"
Write-Host "2. Start all services: pnpm dev" -ForegroundColor $Green
Write-Host "3. Access applications:"
Write-Host "   • User Panel: http://localhost:3002" -ForegroundColor $Blue
Write-Host "   • Admin Panel: http://localhost:3000 (admin/Admin123!)" -ForegroundColor $Blue
Write-Host "   • Backend API: http://localhost:3001" -ForegroundColor $Blue
Write-Host ""
Write-Host "Documentation:" -ForegroundColor $Blue
Write-Host "   • README.md - Project overview"
Write-Host "   • DEVELOPMENT_STATUS.md - Feature checklist"
Write-Host "   • DEPLOYMENT_GUIDE.md - Production deployment"
Write-Host ""
Write-Host "Win5x Casino Game is ready to run!" -ForegroundColor $Green
