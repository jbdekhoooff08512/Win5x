#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Starting Win5x Backend Build Process...\n');

// Clean previous builds
console.log('🧹 Cleaning previous builds...');
if (fs.existsSync('./dist')) {
  fs.rmSync('./dist', { recursive: true, force: true });
}
if (fs.existsSync('./build')) {
  fs.rmSync('./build', { recursive: true, force: true });
}

// Compile TypeScript
console.log('📦 Compiling TypeScript...');
try {
  execSync('npx tsc', { stdio: 'inherit' });
  console.log('✅ TypeScript compilation successful\n');
} catch (error) {
  console.error('❌ TypeScript compilation failed:', error.message);
  process.exit(1);
}

// Create build directory structure
console.log('📁 Creating build directory structure...');
const buildDir = './build';
const distDir = './dist';

// Create main build directory
if (!fs.existsSync(buildDir)) {
  fs.mkdirSync(buildDir, { recursive: true });
}

// Copy dist folder to build/dist
console.log('📋 Copying compiled files to build/dist...');
copyDir(distDir, path.join(buildDir, 'dist'));

// Copy essential files
console.log('📋 Copying essential files...');
const filesToCopy = [
  'package.json',
  'prisma/schema.prisma',
  'prisma/migrations'
];

filesToCopy.forEach(file => {
  const srcPath = path.join('.', file);
  const destPath = path.join(buildDir, file);
  
  if (fs.existsSync(srcPath)) {
    if (fs.statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      copyFile(srcPath, destPath);
    }
    console.log(`  ✓ Copied ${file}`);
  }
});

// Copy uploads directory if it exists
if (fs.existsSync('./uploads')) {
  console.log('📋 Copying uploads directory...');
  copyDir('./uploads', path.join(buildDir, 'uploads'));
}

// Create production package.json
console.log('📝 Creating production package.json...');
const packageJson = JSON.parse(fs.readFileSync('./package.json', 'utf8'));

// Remove devDependencies and scripts not needed in production
const productionPackageJson = {
  ...packageJson,
  scripts: {
    start: 'node dist/server.js',
    'db:migrate': 'prisma migrate deploy',
    'db:generate': 'prisma generate'
  },
  devDependencies: undefined
};

fs.writeFileSync(
  path.join(buildDir, 'package.json'),
  JSON.stringify(productionPackageJson, null, 2)
);

// Create .env.example
console.log('📝 Creating .env.example...');
const envExample = `# Database
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
CORS_ORIGIN="https://nymex.store"

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
`;

fs.writeFileSync(path.join(buildDir, '.env.example'), envExample);

// Create README for build
console.log('📝 Creating build README...');
const buildReadme = `# Win5x Backend Build

This is the production build of the Win5x backend server.

## Structure

- \`dist/\` - Compiled TypeScript files
- \`prisma/\` - Database schema and migrations
- \`uploads/\` - File uploads directory
- \`package.json\` - Production dependencies
- \`.env.example\` - Environment variables template

## Setup

1. Copy \`.env.example\` to \`.env\` and configure your environment variables
2. Install dependencies: \`npm install\`
3. Generate Prisma client: \`npm run db:generate\`
4. Run migrations: \`npm run db:migrate\`
5. Start the server: \`npm start\`

## Environment Variables

See \`.env.example\` for all required environment variables.

## Production Notes

- Make sure Redis is running
- Ensure PostgreSQL database is accessible
- Configure proper CORS origins
- Set up proper logging and monitoring
- Use HTTPS in production
`;

fs.writeFileSync(path.join(buildDir, 'README.md'), buildReadme);

console.log('\n🎉 Build completed successfully!');
console.log(`📦 Build output: ${path.resolve(buildDir)}`);
console.log('\n📋 Next steps:');
console.log('1. Copy the build folder to your production server');
console.log('2. Copy .env.example to .env and configure your environment');
console.log('3. Run: npm install && npm run db:generate && npm run db:migrate && npm start');

// Helper functions
function copyDir(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }
  
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      copyFile(srcPath, destPath);
    }
  }
}

function copyFile(src, dest) {
  const destDir = path.dirname(dest);
  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }
  fs.copyFileSync(src, dest);
}
