# PostgreSQL Database Setup Script for Win5x
# This script creates a new database and seeds it with initial data

Write-Host "Win5x PostgreSQL Database Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Database configuration
$DB_NAME = "win5x_db"
$DB_USER = "win5x_user"
$DB_PASSWORD = "win5x_password123"
$DB_HOST = "localhost"
$DB_PORT = "5432"

# Check if PostgreSQL is installed
try {
    $psqlVersion = & psql --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL not found"
    }
    Write-Host "PostgreSQL found: $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "PostgreSQL is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please run the install-postgresql.ps1 script first." -ForegroundColor Yellow
    exit 1
}

# Set environment variables for the session
$env:PGPASSWORD = "postgres123"  # Default superuser password from installer

Write-Host "Creating database and user..." -ForegroundColor Yellow

# Create database and user
$createDbScript = @"
-- Create database
CREATE DATABASE $DB_NAME;

-- Create user
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
"@

try {
    $createDbScript | & psql -U postgres -h $DB_HOST -p $DB_PORT
    Write-Host "Database and user created successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error creating database: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set environment variables for the new database
$env:PGPASSWORD = $DB_PASSWORD

Write-Host "Running Prisma migrations..." -ForegroundColor Yellow

# Navigate to backend directory
Set-Location "packages/backend"

# Create .env file with database URL
$envContent = @"
# Database
DATABASE_URL="postgresql://$DB_USER`:$DB_PASSWORD@$DB_HOST`:$DB_PORT/$DB_NAME?schema=public"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_EXPIRES_IN="7d"

# Redis
REDIS_URL="redis://localhost:6379"

# Server
PORT=3001
NODE_ENV="development"

# Admin
ADMIN_EMAIL="admin@win5x.com"
ADMIN_PASSWORD="admin123"

# Payment
USDT_TO_INR_RATE=83.0
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "Created .env file with database configuration" -ForegroundColor Green

# Generate Prisma client
Write-Host "Generating Prisma client..." -ForegroundColor Yellow
& npm run db:generate

# Run migrations
Write-Host "Running database migrations..." -ForegroundColor Yellow
& npm run db:migrate

# Seed the database
Write-Host "Seeding database with initial data..." -ForegroundColor Yellow
& npm run db:seed

Write-Host "Database setup completed successfully!" -ForegroundColor Green
Write-Host "Database Name: $DB_NAME" -ForegroundColor Cyan
Write-Host "Database User: $DB_USER" -ForegroundColor Cyan
Write-Host "Database Host: $DB_HOST" -ForegroundColor Cyan
Write-Host "Database Port: $DB_PORT" -ForegroundColor Cyan

Write-Host "You can now start the backend server with: npm run dev" -ForegroundColor Yellow

# Return to original directory
Set-Location "../.."
