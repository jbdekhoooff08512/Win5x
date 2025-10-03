# Win5x Server Build

This folder contains the production-ready build of the Win5x application.

## Structure

```
server/
├── backend/          # Backend source code and configuration
│   ├── src/         # TypeScript source files
│   ├── prisma/      # Database schema and migrations
│   ├── uploads/     # User uploaded files
│   ├── package.json # Backend dependencies
│   └── tsconfig.json # TypeScript configuration
├── common/          # Shared utilities and types
│   ├── dist/        # Compiled common package
│   ├── src/         # Common source files
│   └── package.json # Common package dependencies
├── admin/           # Admin panel build (static files)
├── user/            # User panel build (static files)
├── package.json     # Server package configuration
├── ecosystem.config.js # PM2 configuration
└── nginx-win5x.conf # Nginx configuration
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   cd server/backend
   npm install
   ```

2. **Database Setup**
   ```bash
   cd server/backend
   npx prisma migrate deploy
   npx prisma generate
   ```

3. **Start Server**
   ```bash
   cd server
   npm start
   ```

## Frontend Builds

- **Admin Panel**: Built and ready in `admin/` folder
- **User Panel**: Built and ready in `user/` folder
- **Common Package**: Shared utilities and types in `common/` folder

Both frontends are production builds with optimized assets and depend on the common package for shared functionality.

## Configuration Files

- `ecosystem.config.js`: PM2 process management
- `nginx-win5x.conf`: Nginx reverse proxy configuration
- `package.json`: Server package configuration
