# Win5x Master Setup Scripts

## Overview

This repository contains comprehensive master setup scripts that handle everything from start to end without errors. The scripts automatically install, configure, and deploy the complete Win5x application stack.

## 🚀 Features

- **Complete Automation**: Handles everything from system packages to application deployment
- **Error Handling**: Comprehensive error handling with rollback mechanisms
- **Validation**: System requirements and port availability validation
- **Health Checks**: Post-installation health verification
- **Cross-Platform**: Available for both Linux (Bash) and Windows (PowerShell)
- **Production Ready**: Creates production-ready builds with proper configuration
- **Backup & Restore**: Automatic backup creation and restore capabilities

## 📋 What Gets Installed

### System Components
- **Node.js 18.x** - JavaScript runtime
- **pnpm** - Package manager
- **PM2** - Process manager
- **PostgreSQL** - Database server
- **Redis** - Cache server
- **Nginx** - Web server
- **Essential system packages**

### Application Stack
- **Backend API** - Node.js/Express server
- **Admin Panel** - React frontend
- **User Panel** - React frontend
- **Database Schema** - Prisma migrations
- **Environment Configuration** - Production-ready settings

## 🛠️ Available Scripts

### 1. Linux/Ubuntu (Bash)
**File:** `master-setup.sh`

```bash
# Make executable
chmod +x master-setup.sh

# Run with default settings
./master-setup.sh

# Run with custom configuration
export SERVER_IP="192.168.1.100"
export USER_PORT="8080"
export ADMIN_PORT="8081"
export BACKEND_PORT="8082"
export ADMIN_USERNAME="myadmin"
export ADMIN_PASSWORD="MySecurePass123"
./master-setup.sh
```

### 2. Windows/Linux with PowerShell
**File:** `master-setup.ps1`

```powershell
# Basic usage
.\master-setup.ps1

# Custom configuration
.\master-setup.ps1 -ServerIP "192.168.1.100" -UserPort 8080 -AdminPort 8081 -BackendPort 8082 -AdminUsername "myadmin" -AdminPassword "MySecurePass123"
```

## ⚙️ Configuration Options

### Environment Variables (Bash)
```bash
# Database
DATABASE_PASSWORD="Win5xDB@2024"

# Admin User
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@win5x.com"
ADMIN_PASSWORD="Admin@123"

# Security
JWT_SECRET="your-jwt-secret-here"
REDIS_PASSWORD="Redis@2024"

# Server Configuration
PROJECT_PATH="/var/www/win5x"
SERVER_IP="your-server-ip"
USER_PORT="8080"
ADMIN_PORT="8081"
BACKEND_PORT="8082"
REDIS_PORT="6379"
POSTGRES_PORT="5432"
NGINX_PORT="80"
```

### Parameters (PowerShell)
```powershell
param(
    [string]$DatabasePassword = "Win5xDB@2024",
    [string]$AdminUsername = "admin",
    [string]$AdminEmail = "admin@win5x.com",
    [string]$AdminPassword = "Admin@123",
    [string]$JwtSecret = "your-jwt-secret-here",
    [string]$RedisPassword = "Redis@2024",
    [string]$ProjectPath = "/var/www/win5x",
    [string]$ServerIP = "",
    [int]$UserPort = 8080,
    [int]$AdminPort = 8081,
    [int]$BackendPort = 8082,
    [int]$RedisPort = 6379,
    [int]$PostgresPort = 5432,
    [int]$NginxPort = 80
)
```

## 🔧 Prerequisites

### System Requirements
- **OS**: Ubuntu 18.04+ or Windows 10+ with WSL
- **RAM**: Minimum 1GB (2GB recommended)
- **Disk Space**: Minimum 2GB free space
- **Network**: Internet connection for package downloads
- **Permissions**: Non-root user with sudo access

### Required Access
- SSH access to the server
- Sudo/Administrator privileges
- Ability to install system packages
- Port access (22, 80, 443, 8080-8082, 5432, 6379)

## 📦 Installation Process

The scripts follow this comprehensive process:

### 1. **Pre-Installation Validation**
- System requirements check
- Port availability validation
- Disk space verification
- Memory availability check

### 2. **System Backup**
- Creates backup of existing configurations
- Stores backup in `/tmp/win5x-backup-{timestamp}/`

### 3. **Package Installation**
- Updates package lists
- Installs essential system packages
- Installs Node.js 18.x
- Installs pnpm, PM2, and serve
- Installs PostgreSQL, Redis, and Nginx

### 4. **Project Setup**
- Creates project directory
- Copies project files
- Installs dependencies
- Sets up database

### 5. **Configuration**
- Creates environment files
- Configures database
- Sets up Redis
- Configures Nginx
- Sets up firewall rules

### 6. **Build & Deploy**
- Builds common package
- Creates production build for backend
- Builds frontend applications
- Runs database migrations
- Creates admin user

### 7. **Service Management**
- Sets up PM2 ecosystem
- Configures Nginx reverse proxy
- Starts all services
- Enables auto-start

### 8. **Health Checks**
- Verifies PostgreSQL is running
- Verifies Redis is running
- Verifies Nginx is running
- Verifies PM2 processes are online
- Tests API endpoints

## 🌐 Access URLs

After successful installation:

### Through Nginx (Recommended)
- **User Panel**: `http://YOUR_SERVER_IP/`
- **Admin Panel**: `http://YOUR_SERVER_IP/admin`
- **API**: `http://YOUR_SERVER_IP/api`

### Direct Access (Development/Debug)
- **User Panel**: `http://YOUR_SERVER_IP:8080`
- **Admin Panel**: `http://YOUR_SERVER_IP:8081`
- **Backend API**: `http://YOUR_SERVER_IP:8082`

## 👤 Default Credentials

- **Username**: admin
- **Email**: admin@win5x.com
- **Password**: Admin@123

⚠️ **IMPORTANT**: Change these credentials immediately after setup!

## 🔧 Management Commands

### PM2 Process Management
```bash
# Check status
pm2 status

# View logs
pm2 logs

# Restart all services
pm2 restart all

# Stop all services
pm2 stop all

# Start all services
pm2 start all

# Monitor processes
pm2 monit
```

### Database Access
```bash
# Connect to PostgreSQL
psql -h localhost -p 5432 -U win5x_user -d win5x_db

# Connect to Redis
redis-cli -p 6379 -a Redis@2024
```

### Service Management
```bash
# Nginx
sudo systemctl status nginx
sudo systemctl reload nginx
sudo systemctl restart nginx

# PostgreSQL
sudo systemctl status postgresql
sudo systemctl restart postgresql

# Redis
sudo systemctl status redis-server
sudo systemctl restart redis-server
```

## 📊 Port Configuration

| Service | Default Port | Description |
|---------|-------------|-------------|
| User Panel | 8080 | Frontend user interface |
| Admin Panel | 8081 | Admin dashboard |
| Backend API | 8082 | Node.js API server |
| Nginx | 80 | Web server/proxy |
| PostgreSQL | 5432 | Database server |
| Redis | 6379 | Cache server |

## 🔒 Security Considerations

### Immediate Actions Required
1. **Change Default Passwords**
   - Database password
   - Redis password
   - Admin credentials
   - JWT secret

2. **SSL/HTTPS Setup**
   - Configure SSL certificates
   - Update Nginx configuration for HTTPS
   - Update environment variables for HTTPS URLs

3. **Firewall Review**
   - Verify only necessary ports are open
   - Consider restricting access to admin ports

4. **Database Security**
   - PostgreSQL is configured for local access only
   - Strong password required
   - Limited user privileges

## 🐛 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check port usage
netstat -tulpn | grep :PORT

# Kill process using port
sudo fuser -k PORT/tcp

# Use different ports in script parameters
```

#### 2. Permission Issues
```bash
# Check file ownership
ls -la /var/www/win5x

# Fix ownership
sudo chown -R $USER:$USER /var/www/win5x
```

#### 3. Database Connection Issues
```bash
# Verify PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -h localhost -U win5x_user -d win5x_db

# Check database credentials in .env files
```

#### 4. PM2 Issues
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs

# Restart services
pm2 restart all

# Delete and recreate PM2 processes
pm2 delete all
pm2 start ecosystem.config.js
```

#### 5. Build Issues
```bash
# Clean and rebuild
cd packages/backend
pnpm run clean
pnpm run build:prod

# Check for TypeScript errors
pnpm run build
```

### Log Files
- **Setup Log**: `/tmp/win5x-setup-{timestamp}.log`
- **PM2 Logs**: `./logs/` directory
- **Nginx Logs**: `/var/log/nginx/`
- **PostgreSQL Logs**: `/var/log/postgresql/`
- **Redis Logs**: `/var/log/redis/`

## 🔄 Backup & Restore

### Automatic Backup
The scripts automatically create backups before making changes:
- Location: `/tmp/win5x-backup-{timestamp}/`
- Includes: Nginx config, Redis config, PostgreSQL config

### Manual Backup
```bash
# Create manual backup
mkdir -p /tmp/win5x-manual-backup
cp -r /var/www/win5x /tmp/win5x-manual-backup/
cp /etc/nginx/sites-available/win5x /tmp/win5x-manual-backup/
cp /etc/redis/redis.conf /tmp/win5x-manual-backup/
```

### Restore from Backup
```bash
# Restore project files
cp -r /tmp/win5x-manual-backup/win5x/* /var/www/win5x/

# Restore configurations
sudo cp /tmp/win5x-manual-backup/win5x /etc/nginx/sites-available/
sudo cp /tmp/win5x-manual-backup/redis.conf /etc/redis/
sudo systemctl reload nginx
sudo systemctl restart redis-server
```

## 📈 Monitoring & Maintenance

### Health Monitoring
```bash
# Check all services
sudo systemctl status postgresql redis-server nginx
pm2 status

# Check disk space
df -h

# Check memory usage
free -h

# Check system load
uptime
```

### Log Monitoring
```bash
# Monitor PM2 logs in real-time
pm2 logs --follow

# Monitor Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Monitor system logs
sudo journalctl -f
```

### Performance Optimization
```bash
# Optimize PostgreSQL
sudo -u postgres psql -c "VACUUM ANALYZE;"

# Clear Redis cache
redis-cli -p 6379 -a Redis@2024 FLUSHALL

# Restart services
pm2 restart all
```

## 🆘 Support

### Getting Help
1. **Check Log Files**: Always check log files first
2. **Verify Services**: Ensure all services are running
3. **Test Connectivity**: Test network connectivity to all ports
4. **Review Configuration**: Check environment variables and config files
5. **Check Permissions**: Verify file permissions and ownership

### Common Commands for Debugging
```bash
# Check system status
sudo systemctl status postgresql redis-server nginx
pm2 status

# Check logs
pm2 logs
sudo tail -f /var/log/nginx/error.log

# Test database connection
psql -h localhost -U win5x_user -d win5x_db

# Test Redis connection
redis-cli -p 6379 -a Redis@2024 ping

# Test API endpoint
curl http://localhost:8082/api/health
```

## 📝 Changelog

### Version 2.0.0
- Added comprehensive error handling
- Added system validation
- Added health checks
- Added backup/restore functionality
- Added production build system
- Added cross-platform support
- Improved logging and output formatting

### Version 1.0.0
- Initial release
- Basic setup functionality
- Single platform support

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Contact

For support or questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review log files for error details
