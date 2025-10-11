# 🚀 Win5x Developer Setup Guide

## 📋 **Project Overview**
Win5x ek complete gaming platform hai with:
- **User Frontend** (React + Vite) - Port 8080
- **Admin Frontend** (React + Vite) - Port 8081  
- **Backend API** (Node.js + Express) - Port 8082
- **Database** (PostgreSQL)
- **Cache** (Redis)

## 🛠️ **Quick Setup**

### **1. Install Dependencies**
```bash
# Install pnpm globally
npm install -g pnpm

# Install all dependencies
pnpm install
```

### **2. Database Setup**
```bash
# Install PostgreSQL
# Windows: Download from postgresql.org
# Ubuntu: sudo apt install postgresql postgresql-contrib

# Create database
sudo -u postgres psql
CREATE DATABASE win5x;
CREATE USER win5x_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x_user;
\q
```

### **3. Redis Setup**
```bash
# Install Redis
# Windows: Download from redis.io
# Ubuntu: sudo apt install redis-server

# Start Redis
redis-server
```

### **4. Environment Configuration**
```bash
# Backend environment
cd packages/backend
cp .env.example .env

# Update .env with your database credentials:
DATABASE_URL="postgresql://win5x_user:your_password@localhost:5432/win5x"
REDIS_URL="redis://localhost:6379"
JWT_SECRET="your-super-secret-jwt-key"
JWT_REFRESH_SECRET="your-super-secret-refresh-key"
PORT=8082
```

### **5. Database Migration**
```bash
cd packages/backend
npx prisma migrate dev
npx prisma generate
```

### **6. Start Development Servers**

**Terminal 1 - Backend:**
```bash
cd packages/backend
npm run dev
```

**Terminal 2 - User Frontend:**
```bash
cd packages/user
npm run dev
```

**Terminal 3 - Admin Frontend:**
```bash
cd packages/admin
npm run dev
```

## 🌐 **Access URLs**

- **User App**: http://localhost:8080
- **Admin App**: http://localhost:8081
- **API**: http://localhost:8082
- **API Health**: http://localhost:8082/health

## 🔧 **Configuration Files**

### **Port Configuration**
- User Frontend: `8080` (hardcoded)
- Admin Frontend: `8081` (hardcoded)
- Backend API: `8082` (hardcoded)

### **API Endpoints**
- Production Server: `https://nymex.store`
- Development Fallback: `http://localhost:3001`

### **Proxy Configuration**
- Vite proxy targets: `https://nymex.store`
- Development fallback: `http://localhost:3001`

## 📁 **Project Structure**

```
Win5x/
├── packages/
│   ├── user/          # User frontend (React + Vite)
│   ├── admin/         # Admin frontend (React + Vite)
│   ├── backend/       # Backend API (Node.js + Express)
│   └── common/        # Shared types and utilities
├── server/            # Production build files
├── ecosystem.config.js # PM2 configuration
├── nginx-win5x.conf   # Nginx configuration
└── package.json       # Root package.json
```

## 🎮 **Game Features**

- **Real-time Gaming**: WebSocket-based live betting
- **User Management**: Registration, login, profiles
- **Admin Panel**: User management, analytics, game control
- **Payment System**: Deposit/withdrawal with multiple methods
- **Referral System**: Multi-level referral rewards
- **Gift Codes**: Promotional gift code system

## 🔐 **Default Admin Credentials**

```bash
# Create admin user
cd packages/backend
node create-admin.js

# Default credentials (change these):
Username: admin
Password: Admin123!
```

## 🚀 **Production Deployment**

### **1. Build Applications**
```bash
# Build all packages
npm run build
```

### **2. PM2 Deployment**
```bash
# Install PM2
npm install -g pm2

# Start with PM2
pm2 start ecosystem.config.js

# Check status
pm2 status
pm2 logs
```

### **3. Nginx Configuration**
```bash
# Copy nginx config
sudo cp nginx-win5x.conf /etc/nginx/sites-available/win5x
sudo ln -s /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🛠️ **Development Commands**

### **Backend Commands**
```bash
cd packages/backend

# Development
npm run dev

# Build
npm run build

# Database
npx prisma migrate dev
npx prisma generate
npx prisma studio

# Create admin
node create-admin.js

# Reset admin password
node reset-admin-password.js
```

### **Frontend Commands**
```bash
# User app
cd packages/user
npm run dev
npm run build

# Admin app  
cd packages/admin
npm run dev
npm run build
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Database Connection Error**
   ```bash
   # Check PostgreSQL status
   sudo systemctl status postgresql
   
   # Check database exists
   sudo -u postgres psql -l
   ```

2. **Redis Connection Error**
   ```bash
   # Check Redis status
   redis-cli ping
   
   # Start Redis
   redis-server
   ```

3. **Port Already in Use**
   ```bash
   # Check what's using port
   lsof -i :8080
   lsof -i :8081
   lsof -i :8082
   
   # Kill process
   kill -9 <PID>
   ```

4. **CORS Errors**
   - Check if backend is running on port 8082
   - Verify proxy configuration in Vite configs

### **Log Locations**
- Backend logs: `packages/backend/logs/`
- PM2 logs: `pm2 logs`
- Nginx logs: `/var/log/nginx/`

## 📚 **API Documentation**

### **Main Endpoints**
- `POST /api/auth/login` - User login
- `POST /api/auth/admin/login` - Admin login
- `GET /api/game/current-round` - Current game round
- `POST /api/game/bet` - Place bet
- `GET /api/user/balance` - User balance
- `POST /api/user/deposit` - Deposit request
- `POST /api/user/withdraw` - Withdrawal request

### **WebSocket Events**
- `join_room` - Join game room
- `place_bet` - Place bet
- `round_update` - Round updates
- `phase_update` - Game phase changes

## 🎯 **Development Tips**

1. **Hot Reload**: All frontend changes auto-reload
2. **API Testing**: Use Postman or curl for API testing
3. **Database**: Use Prisma Studio for database management
4. **Logs**: Check console logs for debugging
5. **WebSocket**: Use browser dev tools to monitor WebSocket connections

## 📞 **Support**

- Check console logs for errors
- Verify all services are running
- Ensure database and Redis are accessible
- Check port availability

---

**Happy Coding! 🚀**

