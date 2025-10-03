const fs = require('fs');
const path = require('path');

const envContent = `# Database Configuration
DATABASE_URL="postgresql://postgres:password@localhost:5432/win5x"

# Redis Configuration
REDIS_URL="redis://localhost:6379"

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-change-this-in-production"

# Server Configuration
NODE_ENV="development"
PORT=3001

# CORS Configuration
CORS_ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3002"

# Security Configuration
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Admin Configuration
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@win5x.com"
ADMIN_PASSWORD="Admin123!"`;

const envPath = path.join(__dirname, '.env');

if (!fs.existsSync(envPath)) {
  fs.writeFileSync(envPath, envContent);
  console.log('✅ Created .env file with default configuration');
  console.log('📝 Please update the DATABASE_URL and REDIS_URL with your actual database credentials');
} else {
  console.log('⚠️  .env file already exists');
}



