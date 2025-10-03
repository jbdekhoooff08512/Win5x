# Win5x Complete Server Setup Guide

## Overview
This guide provides comprehensive setup scripts for the Win5x application after OS reinstallation. The scripts will install and configure all necessary components with specific port configurations.

## Available Scripts

### 1. PowerShell Script (Windows/Linux with PowerShell)
**File:** `complete-server-setup.ps1`

### 2. Bash Script (Linux/Ubuntu)
**File:** `complete-server-setup.sh`

## Default Port Configuration

| Service | Default Port | Description |
|---------|-------------|-------------|
| User Panel | 8080 | Frontend user interface |
| Admin Panel | 8081 | Admin dashboard |
| Backend API | 8082 | Node.js API server |
| Nginx | 80 | Web server/proxy |
| PostgreSQL | 5432 | Database server |
| Redis | 6379 | Cache server |

## Usage

### PowerShell Script Usage
```powershell
# Basic usage with default settings
.\complete-server-setup.ps1

# Custom configuration
.\complete-server-setup.ps1 -ServerIP "192.168.1.100" -UserPort 8080 -AdminPort 8081 -BackendPort 8082 -NginxPort 80

# Full custom configuration
.\complete-server-setup.ps1 `
    -DatabasePassword "MySecureDBPass123" `
    -AdminUsername "myadmin" `
    -AdminEmail "admin@mydomain.com" `
    -AdminPassword "MyAdminPass123" `
    -JwtSecret "my-super-secret-jwt-key" `
    -RedisPassword "MyRedisPass123" `
    -ProjectPath "/var/www/kart" `
    -ServerIP "192.168.1.100" `
    -UserPort 8080 `
    -AdminPort 8081 `
    -BackendPort 8082 `
    -RedisPort 6379 `
    -PostgresPort 5432 `
    -NginxPort 80
```

### Bash Script Usage
```bash
# Make script executable
chmod +x complete-server-setup.sh

# Basic usage with default settings
./complete-server-setup.sh

# Custom configuration using environment variables
export SERVER_IP="192.168.1.100"
export USER_PORT="8080"
export ADMIN_PORT="8081"
export BACKEND_PORT="8082"
export NGINX_PORT="80"
export ADMIN_USERNAME="myadmin"
export ADMIN_PASSWORD="MyAdminPass123"
./complete-server-setup.sh
```

## What the Scripts Install

### System Packages
- Node.js 18.x
- pnpm package manager
- PM2 process manager
- PostgreSQL database
- Redis cache server
- Nginx web server
- Essential system tools

### Application Setup
- Project dependencies installation
- Database schema creation
- Admin user creation
- Environment configuration
- PM2 ecosystem setup
- Nginx reverse proxy configuration
- Firewall rules setup

## Access URLs After Setup

### Through Nginx (Recommended)
- **User Panel:** `http://YOUR_SERVER_IP/`
- **Admin Panel:** `http://YOUR_SERVER_IP/admin`
- **API:** `http://YOUR_SERVER_IP/api`

### Direct Access (Development/Debug)
- **User Panel:** `http://YOUR_SERVER_IP:8080`
- **Admin Panel:** `http://YOUR_SERVER_IP:8081`
- **Backend API:** `http://YOUR_SERVER_IP:8082`

## Default Admin Credentials
- **Username:** admin
- **Email:** admin@win5x.com
- **Password:** Admin@123

⚠️ **IMPORTANT:** Change these credentials immediately after setup!

## Management Commands

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

## Security Considerations

1. **Change Default Passwords**
   - Database password
   - Redis password
   - Admin credentials
   - JWT secret

2. **Firewall Configuration**
   - Only necessary ports are opened
   - SSH access (port 22)
   - HTTP/HTTPS (ports 80/443)
   - Application ports (8080, 8081, 8082)

3. **SSL/HTTPS Setup**
   - Configure SSL certificates
   - Update Nginx configuration for HTTPS
   - Update environment variables for HTTPS URLs

4. **Database Security**
   - PostgreSQL is configured for local access only
   - Strong password required
   - Limited user privileges

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   - Check if ports are available: `netstat -tulpn | grep :PORT`
   - Kill processes using ports: `sudo fuser -k PORT/tcp`
   - Use different ports in script parameters

2. **Permission Issues**
   - Ensure script is run with appropriate permissions
   - Check file ownership: `ls -la /var/www/kart`

3. **Database Connection Issues**
   - Verify PostgreSQL is running: `sudo systemctl status postgresql`
   - Check database credentials in `.env` files
   - Test connection: `psql -h localhost -U win5x_user -d win5x_db`

4. **PM2 Issues**
   - Check PM2 status: `pm2 status`
   - View logs: `pm2 logs`
   - Restart services: `pm2 restart all`

### Log Files
- **PM2 Logs:** `./logs/` directory
- **Nginx Logs:** `/var/log/nginx/`
- **PostgreSQL Logs:** `/var/log/postgresql/`
- **Redis Logs:** `/var/log/redis/`

## Customization

### Environment Variables
Edit the `.env` files in each package:
- `packages/backend/.env`
- `packages/admin/.env`
- `packages/user/.env`

### Port Configuration
Modify the script parameters or environment variables to use different ports.

### Database Configuration
Update PostgreSQL settings in `/etc/postgresql/` for custom database configuration.

### Nginx Configuration
Modify `/etc/nginx/sites-available/win5x` for custom web server settings.

## Support

For issues or questions:
1. Check the log files for error messages
2. Verify all services are running
3. Test network connectivity to all ports
4. Review firewall rules
5. Check file permissions and ownership
