# PostgreSQL Database Setup Script for Win5x (with existing pgAdmin 4)
# This script creates a new database and seeds it with initial data

Write-Host "Win5x PostgreSQL Database Setup (with pgAdmin 4)" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Add PostgreSQL to PATH for this session
$env:PATH += ";C:\Program Files\PostgreSQL\17\bin"

# Database configuration
$DB_NAME = "win5x_db"
$DB_USER = "win5x_user"
$DB_PASSWORD = "win5x_password123"
$DB_HOST = "localhost"
$DB_PORT = "5432"

Write-Host "Step 1: Checking PostgreSQL connection..." -ForegroundColor Yellow

# Test PostgreSQL connection
try {
    $psqlVersion = & psql --version
    Write-Host "✅ PostgreSQL found: $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ PostgreSQL not accessible. Please ensure PostgreSQL service is running." -ForegroundColor Red
    Write-Host "You can start it from Services.msc or pgAdmin 4" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 2: Testing connection to PostgreSQL server..." -ForegroundColor Yellow

# Test connection to PostgreSQL server
try {
    & psql -U postgres -h $DB_HOST -p $DB_PORT -c "SELECT version();" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully connected to PostgreSQL server" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot connect to PostgreSQL server. Please check:" -ForegroundColor Red
        Write-Host "1. PostgreSQL service is running" -ForegroundColor Yellow
        Write-Host "2. Default password for 'postgres' user" -ForegroundColor Yellow
        Write-Host "3. Server is listening on port $DB_PORT" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can check these settings in pgAdmin 4" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "❌ Error connecting to PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Step 3: Creating database and user..." -ForegroundColor Yellow

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
    Write-Host "✅ Database and user created successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creating database: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying to continue with existing database..." -ForegroundColor Yellow
}

Write-Host "Step 4: Setting up project configuration..." -ForegroundColor Yellow

# Navigate to backend directory
$originalLocation = Get-Location
Set-Location "packages/backend"

# Create .env file with database URL
$envContent = @"
# Database
DATABASE_URL="postgresql://$DB_USER`:$DB_PASSWORD@$DB_HOST`:$DB_PORT/$DB_NAME?schema=public"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production-$(Get-Random)"
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
Write-Host "✅ Created .env file with database configuration" -ForegroundColor Green

Write-Host "Step 5: Installing dependencies..." -ForegroundColor Yellow
& npm install

Write-Host "Step 6: Generating Prisma client..." -ForegroundColor Yellow
& npm run db:generate

Write-Host "Step 7: Running database migrations..." -ForegroundColor Yellow
& npm run db:migrate

Write-Host "Step 8: Seeding database with initial data..." -ForegroundColor Yellow
& npm run db:seed

Write-Host "Step 9: Creating admin user..." -ForegroundColor Yellow
& npm run create-admin

Write-Host "🎉 Database setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Database Information:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Database Name: $DB_NAME" -ForegroundColor White
Write-Host "Database User: $DB_USER" -ForegroundColor White
Write-Host "Database Host: $DB_HOST" -ForegroundColor White
Write-Host "Database Port: $DB_PORT" -ForegroundColor White
Write-Host "Admin Email: admin@win5x.com" -ForegroundColor White
Write-Host "Admin Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "You can now view your database in pgAdmin 4:" -ForegroundColor Yellow
Write-Host "1. Open pgAdmin 4" -ForegroundColor White
Write-Host "2. Connect to your PostgreSQL server" -ForegroundColor White
Write-Host "3. Look for database: $DB_NAME" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start Redis server: redis-server" -ForegroundColor White
Write-Host "2. Start backend server: npm run dev" -ForegroundColor White
Write-Host "3. Start frontend: cd ../user && npm run dev" -ForegroundColor White
Write-Host "4. Start admin panel: cd ../admin && npm run dev" -ForegroundColor White

# Return to original directory
Set-Location $originalLocation
