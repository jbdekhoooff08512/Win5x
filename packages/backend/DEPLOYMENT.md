# Win5x Backend Build & Deployment Guide

## Overview

This guide explains how to build and deploy the Win5x backend server for production environments.

## Build Process

The backend now includes a comprehensive build system that creates a production-ready deployment package.

### Available Build Commands

```bash
# Development build (TypeScript compilation only)
npm run build

# Production build (complete build with dist folder)
npm run build:prod

# Clean build (removes old builds first)
npm run build:clean

# Windows PowerShell build
npm run build:win

# Clean Windows build
npm run build:clean:win
```

### Build Output Structure

After running `npm run build:prod`, you'll get a `build/` folder with:

```
build/
├── dist/                    # Compiled TypeScript files
│   ├── controllers/         # API controllers
│   ├── services/           # Business logic services
│   ├── middleware/         # Express middleware
│   ├── database/          # Database utilities
│   ├── websocket/         # Socket.io handlers
│   ├── utils/             # Utility functions
│   └── server.js          # Main server entry point
├── prisma/                # Database schema and migrations
│   ├── schema.prisma
│   └── migrations/
├── uploads/               # File uploads directory
├── package.json           # Production dependencies only
├── .env.example          # Environment variables template
└── README.md             # Deployment instructions
```

## Deployment Steps

### 1. Build the Application

```bash
cd packages/backend
npm run build:prod
```

### 2. Copy Build to Production Server

Copy the entire `build/` folder to your production server.

### 3. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your production values
nano .env
```

Required environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `REDIS_URL` - Redis connection string
- `PORT` - Server port (default: 3001)
- `NODE_ENV` - Set to "production"
- `CORS_ORIGIN` - Frontend URL for CORS

### 4. Install Dependencies

```bash
npm install
```

### 5. Database Setup

```bash
# Generate Prisma client
npm run db:generate

# Run database migrations
npm run db:migrate
```

### 6. Start the Server

```bash
npm start
```

## Production Considerations

### Process Management

For production, consider using PM2:

```bash
# Install PM2 globally
npm install -g pm2

# Start with PM2
pm2 start dist/server.js --name "win5x-backend"

# Save PM2 configuration
pm2 save
pm2 startup
```

### Reverse Proxy

Configure Nginx or Apache as a reverse proxy:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### SSL/HTTPS

- Use Let's Encrypt for free SSL certificates
- Configure HTTPS redirects
- Update CORS_ORIGIN to use HTTPS URLs

### Monitoring

- Set up log rotation
- Configure monitoring (e.g., New Relic, DataDog)
- Set up health checks
- Monitor Redis and PostgreSQL connections

### Security

- Use strong JWT secrets
- Configure proper CORS origins
- Set up rate limiting
- Use HTTPS in production
- Regular security updates

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify DATABASE_URL format
   - Check PostgreSQL is running
   - Ensure database exists

2. **Redis Connection Errors**
   - Verify REDIS_URL format
   - Check Redis is running
   - Test Redis connection

3. **Port Already in Use**
   - Change PORT in .env
   - Kill existing processes on the port

4. **File Upload Issues**
   - Check uploads directory permissions
   - Verify MAX_FILE_SIZE setting

### Logs

Check application logs for errors:
```bash
# If using PM2
pm2 logs win5x-backend

# Direct Node.js
tail -f logs/combined.log
```

## Development vs Production

| Aspect | Development | Production |
|--------|-------------|-----------|
| Build | `npm run build` | `npm run build:prod` |
| Start | `npm run dev` | `npm start` |
| Database | `npm run db:migrate` | `npm run db:migrate:prod` |
| Dependencies | All deps | Production only |
| Logging | Console | File + structured |
| Error Handling | Detailed | Sanitized |

## Support

For issues or questions:
1. Check the logs first
2. Verify environment variables
3. Test database and Redis connections
4. Review this deployment guide
