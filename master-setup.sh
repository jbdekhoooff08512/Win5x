#!/bin/bash

# Win5x Master Setup Script - Complete End-to-End Setup
# This script handles everything from start to end without errors
# Version: 2.0.0
# Author: Win5x Team

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/win5x-setup-$(date +%Y%m%d-%H%M%S).log"
readonly BACKUP_DIR="/tmp/win5x-backup-$(date +%Y%m%d-%H%M%S)"

# Initialize variables
CURRENT_STEP="Initialization"

# Default configuration
DATABASE_PASSWORD="${DATABASE_PASSWORD:-Win5xDB@2024}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@win5x.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@123}"
JWT_SECRET="${JWT_SECRET:-8994ef18d28713eda513d112fabd58b45647514cbabdc8ec9ecf3313bc9628537e4c436e40925e2e6d850dd791f65deb41aaf201b1c4542fe4f838ce632401d4}"
REDIS_PASSWORD="${REDIS_PASSWORD:-Redis@2024}"
PROJECT_PATH="${PROJECT_PATH:-/var/www/win5x}"
SERVER_IP="${SERVER_IP:-$(curl -s ifconfig.me || echo 'localhost')}"
USER_PORT="${USER_PORT:-8080}"
ADMIN_PORT="${ADMIN_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8082}"
REDIS_PORT="${REDIS_PORT:-6379}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
NGINX_PORT="${NGINX_PORT:-80}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_step() {
    log "${PURPLE}🔄 $1${NC}"
}

# Error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Setup failed at step: ${CURRENT_STEP:-Unknown}"
        log_error "Check log file: $LOG_FILE"
        log_error "Backup directory: $BACKUP_DIR"
        
        # Try to restore from backup if it exists
        if [ -d "$BACKUP_DIR" ]; then
            log_warning "Attempting to restore from backup..."
            restore_from_backup
        fi
        
        exit $exit_code
    fi
}

trap cleanup EXIT

# Backup function
backup_system() {
    log_step "Creating system backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing configurations
    [ -f /etc/nginx/sites-available/win5x ] && cp /etc/nginx/sites-available/win5x "$BACKUP_DIR/"
    [ -f /etc/redis/redis.conf ] && cp /etc/redis/redis.conf "$BACKUP_DIR/"
    [ -f /etc/postgresql/*/main/postgresql.conf ] && cp /etc/postgresql/*/main/postgresql.conf "$BACKUP_DIR/"
    
    log_success "System backup created at $BACKUP_DIR"
}

# Restore function
restore_from_backup() {
    if [ -d "$BACKUP_DIR" ]; then
        log_warning "Restoring from backup..."
        [ -f "$BACKUP_DIR/win5x" ] && sudo cp "$BACKUP_DIR/win5x" /etc/nginx/sites-available/
        [ -f "$BACKUP_DIR/redis.conf" ] && sudo cp "$BACKUP_DIR/redis.conf" /etc/redis/
        [ -f "$BACKUP_DIR/postgresql.conf" ] && sudo cp "$BACKUP_DIR/postgresql.conf" /etc/postgresql/*/main/
        log_success "Restored from backup"
    fi
}

# Validation functions
validate_system() {
    log_step "Validating system requirements..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root user. This is allowed but not recommended for security reasons."
        log_warning "Consider creating a non-root user with sudo privileges for production deployments."
        read -p "Do you want to continue as root? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting. Please create a non-root user and run the script again."
            exit 0
        fi
    fi
    
    # Check available disk space (minimum 2GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 2097152 ]; then  # 2GB in KB
        log_error "Insufficient disk space. Need at least 2GB free."
        exit 1
    fi
    
    # Check available memory (minimum 1GB)
    local available_memory=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_memory" -lt 1024 ]; then
        log_warning "Low memory detected. Performance may be affected."
    fi
    
    log_success "System validation passed"
}

validate_ports() {
    log_step "Validating port availability..."
    
    local ports=("$USER_PORT" "$ADMIN_PORT" "$BACKEND_PORT" "$NGINX_PORT" "$POSTGRES_PORT" "$REDIS_PORT")
    local port_names=("User Panel" "Admin Panel" "Backend API" "Nginx" "PostgreSQL" "Redis")
    local in_use_ports=()
    
    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        local name="${port_names[$i]}"
        
        if netstat -tuln | grep -q ":$port "; then
            in_use_ports+=("$name (port $port)")
            log_warning "Port $port ($name) is already in use"
        fi
    done
    
    if [ ${#in_use_ports[@]} -gt 0 ]; then
        log_warning "Found ${#in_use_ports[@]} ports already in use: ${in_use_ports[*]}"
        log_info "This usually means the services are already running, which is normal for existing installations"
        log_info "The script will attempt to configure and use the existing services"
        
        # Only fail for critical ports that we can't work around
        local critical_ports=("$USER_PORT" "$ADMIN_PORT" "$BACKEND_PORT")
        for port in "${critical_ports[@]}"; do
            if netstat -tuln | grep -q ":$port "; then
                log_error "Critical port $port is in use. Please stop the service using this port or use different ports."
                log_info "You can set different ports using environment variables:"
                log_info "USER_PORT=8083 ADMIN_PORT=8084 BACKEND_PORT=8085 ./master-setup.sh"
                exit 1
            fi
        done
        
        log_success "Port validation completed - will work with existing services"
    else
        log_success "All ports are available"
    fi
}

# Command execution with error handling
run_command() {
    local command="$1"
    local description="$2"
    local allow_failure="${3:-false}"
    
    CURRENT_STEP="$description"
    log_step "$description"
    
    # Remove sudo if running as root
    if [ "$EUID" -eq 0 ]; then
        command=$(echo "$command" | sed 's/sudo //g')
    fi
    
    if eval "$command" >> "$LOG_FILE" 2>&1; then
        log_success "$description completed"
        return 0
    else
        if [ "$allow_failure" = "true" ]; then
            log_warning "$description failed (allowed)"
            return 1
        else
            log_error "$description failed"
            exit 1
        fi
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system packages
install_system_packages() {
    log_step "Installing system packages..."
    
    # Update package lists
    run_command "sudo apt update" "Package list update"
    
    # Install essential packages
    local essential_packages=(
        "curl" "wget" "git" "unzip" "software-properties-common"
        "apt-transport-https" "ca-certificates" "gnupg" "lsb-release"
        "build-essential" "python3" "python3-pip"
    )
    
    run_command "sudo apt install -y ${essential_packages[*]}" "Essential packages installation"
    
    log_success "System packages installed"
}

# Install Node.js
install_nodejs() {
    log_step "Installing Node.js..."
    
    if ! command_exists node; then
        # Install Node.js 18.x
        run_command "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
        run_command "sudo apt install -y nodejs" "Node.js installation"
    else
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -lt 18 ]; then
            log_warning "Node.js version $node_version detected. Upgrading to 18.x..."
            run_command "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -" "Node.js repository setup"
            run_command "sudo apt install -y nodejs" "Node.js installation"
        fi
    fi
    
    # Install pnpm
    if ! command_exists pnpm; then
        run_command "npm install -g pnpm@8.15.0" "pnpm installation"
    fi
    
    # Install PM2
    if ! command_exists pm2; then
        run_command "npm install -g pm2" "PM2 installation"
    fi
    
    # Install serve
    run_command "npm install -g serve" "Serve installation"
    
    log_success "Node.js ecosystem installed"
}

# Install PostgreSQL
install_postgresql() {
    log_step "Installing PostgreSQL..."
    
    if ! command_exists psql; then
        run_command "sudo apt install -y postgresql postgresql-contrib" "PostgreSQL installation"
        run_command "sudo systemctl start postgresql" "PostgreSQL service start"
        run_command "sudo systemctl enable postgresql" "PostgreSQL service enable"
    else
        log_info "PostgreSQL already installed"
        
        # Check if PostgreSQL is running
        if sudo systemctl is-active --quiet postgresql; then
            log_info "PostgreSQL is already running"
        else
            log_warning "PostgreSQL is installed but not running. Starting service..."
            run_command "sudo systemctl start postgresql" "PostgreSQL service start"
            run_command "sudo systemctl enable postgresql" "PostgreSQL service enable"
        fi
        
        # Test PostgreSQL connection
        if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
            log_success "PostgreSQL connection test successful"
        else
            log_error "PostgreSQL connection test failed"
            log_info "Trying to restart PostgreSQL service..."
            run_command "sudo systemctl restart postgresql" "PostgreSQL service restart"
            
            # Wait a moment for service to start
            sleep 3
            
            # Test connection again
            if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
                log_success "PostgreSQL connection test successful after restart"
            else
                log_error "PostgreSQL is still not responding. Please check the service manually."
                log_info "Run these commands to troubleshoot:"
                log_info "sudo systemctl status postgresql"
                log_info "sudo journalctl -u postgresql"
                exit 1
            fi
        fi
    fi
    
    log_success "PostgreSQL installed and configured"
}

# Install Redis
install_redis() {
    log_step "Installing Redis..."
    
    if ! command_exists redis-server; then
        run_command "sudo apt install -y redis-server" "Redis installation"
        
        # Configure Redis
        local redis_config="/etc/redis/redis.conf"
        run_command "sudo cp $redis_config $redis_config.backup" "Redis config backup"
        
        # Update Redis configuration
        sudo sed -i "s/^# requirepass.*/requirepass $REDIS_PASSWORD/" "$redis_config"
        sudo sed -i "s/^# maxmemory.*/maxmemory 256mb/" "$redis_config"
        sudo sed -i "s/^# maxmemory-policy.*/maxmemory-policy allkeys-lru/" "$redis_config"
        
        run_command "sudo systemctl start redis-server" "Redis service start"
        run_command "sudo systemctl enable redis-server" "Redis service enable"
    else
        log_info "Redis already installed"
        
        # Check if Redis is running and configure if needed
        if sudo systemctl is-active --quiet redis-server; then
            log_info "Redis is already running"
        else
            log_info "Starting Redis service"
            run_command "sudo systemctl start redis-server" "Redis service start"
            run_command "sudo systemctl enable redis-server" "Redis service enable"
        fi
        
        # Update Redis configuration if needed
        local redis_config="/etc/redis/redis.conf"
        if ! grep -q "requirepass $REDIS_PASSWORD" "$redis_config"; then
            log_info "Updating Redis configuration"
            run_command "sudo cp $redis_config $redis_config.backup" "Redis config backup"
            sudo sed -i "s/^# requirepass.*/requirepass $REDIS_PASSWORD/" "$redis_config"
            sudo sed -i "s/^# maxmemory.*/maxmemory 256mb/" "$redis_config"
            sudo sed -i "s/^# maxmemory-policy.*/maxmemory-policy allkeys-lru/" "$redis_config"
            run_command "sudo systemctl restart redis-server" "Redis service restart"
        fi
    fi
    
    log_success "Redis installed and configured"
}

# Install Nginx
install_nginx() {
    log_step "Installing Nginx..."
    
    if ! command_exists nginx; then
        run_command "sudo apt install -y nginx" "Nginx installation"
        run_command "sudo systemctl start nginx" "Nginx service start"
        run_command "sudo systemctl enable nginx" "Nginx service enable"
    else
        log_info "Nginx already installed"
    fi
    
    log_success "Nginx installed and configured"
}

# Setup project
setup_project() {
    log_step "Setting up project..."
    
    # Create project directory
    run_command "sudo mkdir -p $PROJECT_PATH" "Project directory creation"
    if [ "$EUID" -eq 0 ]; then
        # Running as root, no need to change ownership
        log_info "Running as root, skipping ownership change"
    else
        run_command "sudo chown -R $USER:$USER $PROJECT_PATH" "Project directory ownership"
    fi
    
    # If we're in the project directory, copy files
    if [ -f "package.json" ] && [ -f "pnpm-workspace.yaml" ]; then
        log_info "Detected existing project. Copying files..."
        run_command "cp -r . $PROJECT_PATH/" "Project files copy"
    else
        log_warning "No existing project detected. Please ensure project files are available."
        log_info "You can clone your repository or copy files to $PROJECT_PATH"
    fi
    
    # Navigate to project directory
    cd "$PROJECT_PATH"
    
    log_success "Project setup completed"
}

# Install project dependencies
install_dependencies() {
    log_step "Installing project dependencies..."
    
    cd "$PROJECT_PATH"
    
    # Install dependencies
    run_command "pnpm install" "Project dependencies installation"
    
    log_success "Dependencies installed"
}

# Setup database
setup_database() {
    log_step "Setting up database..."
    
    local db_name="win5x_db"
    local db_user="win5x_user"
    
    # Test PostgreSQL connection first
    if ! sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        log_error "Cannot connect to PostgreSQL. Please ensure PostgreSQL is running."
        log_info "Run these commands to fix PostgreSQL:"
        log_info "sudo systemctl start postgresql"
        log_info "sudo systemctl enable postgresql"
        log_info "sudo systemctl status postgresql"
        exit 1
    fi
    
    # Check if database exists
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        log_info "Database '$db_name' already exists"
    else
        run_command "sudo -u postgres psql -c \"CREATE DATABASE $db_name;\"" "Database creation"
    fi
    
    # Check if user exists
    if sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$db_user'" | grep -q "1 row"; then
        log_info "Database user '$db_user' already exists"
    else
        run_command "sudo -u postgres psql -c \"CREATE USER $db_user WITH PASSWORD '$DATABASE_PASSWORD';\"" "Database user creation"
    fi
    
    # Grant privileges (this will work even if user/database already exists)
    run_command "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;\"" "Database privileges"
    
    log_success "Database setup completed"
}

# Create environment files
create_environment_files() {
    log_step "Creating environment files..."
    
    cd "$PROJECT_PATH"
    
    # Backend .env
    cat > packages/backend/.env << EOF
# Database
DATABASE_URL="postgresql://win5x_user:$DATABASE_PASSWORD@localhost:$POSTGRES_PORT/win5x_db"

# JWT
JWT_SECRET="$JWT_SECRET"
JWT_EXPIRES_IN="24h"

# Redis
REDIS_URL="redis://:$REDIS_PASSWORD@localhost:$REDIS_PORT"

# Server
PORT=$BACKEND_PORT
NODE_ENV=production

# Admin credentials
ADMIN_USERNAME="$ADMIN_USERNAME"
ADMIN_EMAIL="$ADMIN_EMAIL"
ADMIN_PASSWORD="$ADMIN_PASSWORD"

# Security
BCRYPT_ROUNDS=12

# File uploads
UPLOAD_DIR="./uploads"
MAX_FILE_SIZE=5242880

# Game settings
GAME_BETTING_DURATION=30
GAME_SPIN_DURATION=10
GAME_RESULT_DURATION=15

# Payment settings
USDT_TO_INR_RATE=83.0
DEPOSIT_BONUS_PERCENTAGE=5

# Referral settings
REFERRAL_LEVEL1_PERCENTAGE=5
REFERRAL_LEVEL2_PERCENTAGE=3
REFERRAL_LEVEL3_PERCENTAGE=1

# Attendance
ATTENDANCE_DAY7_AMOUNT=60

# CORS
CORS_ORIGIN="http://$SERVER_IP:$NGINX_PORT"
EOF

    # Admin .env
    cat > packages/admin/.env << EOF
VITE_API_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_SOCKET_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_APP_NAME=Win5x Admin
VITE_APP_VERSION=1.0.0
EOF

    # User .env
    cat > packages/user/.env << EOF
VITE_API_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_SOCKET_URL=http://$SERVER_IP:$BACKEND_PORT
VITE_APP_NAME=Win5x
VITE_APP_VERSION=1.0.0
EOF

    log_success "Environment files created"
}

# Build project
build_project() {
    log_step "Building project..."
    
    cd "$PROJECT_PATH"
    
    # Build common package first
    run_command "cd packages/common && pnpm run build" "Common package build"
    
    # Build backend
    run_command "cd packages/backend && pnpm run build:prod" "Backend production build"
    
    # Build frontend packages
    run_command "cd packages/admin && pnpm run build" "Admin frontend build"
    run_command "cd packages/user && pnpm run build" "User frontend build"
    
    log_success "Project build completed"
}

# Setup database schema
setup_database_schema() {
    log_step "Setting up database schema..."
    
    cd "$PROJECT_PATH/packages/backend"
    
    # Generate Prisma client
    run_command "pnpm run db:generate" "Prisma client generation"
    
    # Run migrations (this will handle existing migrations gracefully)
    run_command "pnpm run db:migrate:prod" "Database migration"
    
    # Create admin user (check if admin already exists first)
    export ADMIN_USERNAME="$ADMIN_USERNAME"
    export ADMIN_EMAIL="$ADMIN_EMAIL"
    export ADMIN_PASSWORD="$ADMIN_PASSWORD"
    
    # Check if admin user already exists
    if pnpm run create-admin 2>&1 | grep -q "already exists"; then
        log_info "Admin user already exists, skipping creation"
    else
        run_command "pnpm run create-admin" "Admin user creation"
    fi
    
    cd "$PROJECT_PATH"
    
    log_success "Database schema setup completed"
}

# Setup PM2 ecosystem
setup_pm2() {
    log_step "Setting up PM2 ecosystem..."
    
    cd "$PROJECT_PATH"
    
    # Create logs directory
    run_command "mkdir -p logs" "Logs directory creation"
    
    # Create PM2 ecosystem file
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/build/dist/server.js',
      cwd: '$PROJECT_PATH',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: $BACKEND_PORT
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-admin',
      script: 'serve',
      args: '-s packages/admin/dist -p $ADMIN_PORT',
      cwd: '$PROJECT_PATH',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      log_file: './logs/admin-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-user',
      script: 'serve',
      args: '-s packages/user/dist -p $USER_PORT',
      cwd: '$PROJECT_PATH',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/user-error.log',
      out_file: './logs/user-out.log',
      log_file: './logs/user-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
EOF

    log_success "PM2 ecosystem configured"
}

# Setup Nginx
setup_nginx() {
    log_step "Setting up Nginx configuration..."
    
    # Create Nginx configuration
    cat > /tmp/win5x-nginx.conf << EOF
server {
    listen $NGINX_PORT;
    server_name _;

    # User panel
    location / {
        proxy_pass http://localhost:$USER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Admin panel
    location /admin {
        proxy_pass http://localhost:$ADMIN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # API
    location /api {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Socket.io
    location /socket.io/ {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Install Nginx configuration
    run_command "sudo cp /tmp/win5x-nginx.conf /etc/nginx/sites-available/win5x" "Nginx config copy"
    run_command "sudo ln -sf /etc/nginx/sites-available/win5x /etc/nginx/sites-enabled/" "Nginx site enable"
    run_command "sudo rm -f /etc/nginx/sites-enabled/default" "Default Nginx site removal"
    run_command "sudo nginx -t" "Nginx configuration test"
    run_command "sudo systemctl reload nginx" "Nginx reload"
    
    log_success "Nginx configured"
}

# Setup firewall
setup_firewall() {
    log_step "Setting up firewall..."
    
    # Configure UFW
    run_command "sudo ufw allow 22" "SSH firewall rule"
    run_command "sudo ufw allow $NGINX_PORT" "HTTP firewall rule"
    run_command "sudo ufw allow 443" "HTTPS firewall rule"
    run_command "sudo ufw allow $USER_PORT" "User panel firewall rule"
    run_command "sudo ufw allow $ADMIN_PORT" "Admin panel firewall rule"
    run_command "sudo ufw allow $BACKEND_PORT" "Backend API firewall rule"
    run_command "sudo ufw --force enable" "Firewall enable"
    
    log_success "Firewall configured"
}

# Start services
start_services() {
    log_step "Starting services..."
    
    cd "$PROJECT_PATH"
    
    # Start PM2 applications
    run_command "pm2 start ecosystem.config.js" "PM2 applications start"
    run_command "pm2 save" "PM2 configuration save"
    run_command "pm2 startup" "PM2 startup configuration"
    
    log_success "Services started"
}

# Health checks
perform_health_checks() {
    log_step "Performing health checks..."
    
    # Check PostgreSQL
    if sudo systemctl is-active --quiet postgresql; then
        log_success "PostgreSQL is running"
    else
        log_error "PostgreSQL is not running"
        return 1
    fi
    
    # Check Redis
    if sudo systemctl is-active --quiet redis-server; then
        log_success "Redis is running"
    else
        log_error "Redis is not running"
        return 1
    fi
    
    # Check Nginx
    if sudo systemctl is-active --quiet nginx; then
        log_success "Nginx is running"
    else
        log_error "Nginx is not running"
        return 1
    fi
    
    # Check PM2 processes
    if pm2 list | grep -q "online"; then
        log_success "PM2 processes are running"
    else
        log_error "PM2 processes are not running"
        return 1
    fi
    
    # Test API endpoint
    sleep 5  # Wait for services to start
    if curl -s "http://localhost:$BACKEND_PORT/api/health" >/dev/null 2>&1; then
        log_success "API endpoint is responding"
    else
        log_warning "API endpoint health check failed (this may be normal if no health endpoint exists)"
    fi
    
    log_success "Health checks completed"
}

# Display final information
display_final_info() {
    log ""
    log "${CYAN}===============================================${NC}"
    log "${GREEN}🎉 Win5x Master Setup Complete!${NC}"
    log "${CYAN}===============================================${NC}"
    log ""
    log "${YELLOW}📋 Setup Summary:${NC}"
    log "• Database: PostgreSQL (win5x_db)"
    log "• Cache: Redis with password protection"
    log "• Web Server: Nginx"
    log "• Process Manager: PM2"
    log "• Build System: Production-ready build created"
    log ""
    log "${YELLOW}🌐 Access URLs:${NC}"
    log "• User Panel: http://$SERVER_IP:$NGINX_PORT/"
    log "• Admin Panel: http://$SERVER_IP:$NGINX_PORT/admin"
    log "• API: http://$SERVER_IP:$NGINX_PORT/api"
    log "• Direct User Panel: http://$SERVER_IP:$USER_PORT"
    log "• Direct Admin Panel: http://$SERVER_IP:$ADMIN_PORT"
    log "• Direct Backend API: http://$SERVER_IP:$BACKEND_PORT"
    log ""
    log "${YELLOW}👤 Admin Credentials:${NC}"
    log "• Username: $ADMIN_USERNAME"
    log "• Email: $ADMIN_EMAIL"
    log "• Password: $ADMIN_PASSWORD"
    log ""
    log "${YELLOW}🔧 Management Commands:${NC}"
    log "• PM2 Status: pm2 status"
    log "• PM2 Logs: pm2 logs"
    log "• PM2 Restart: pm2 restart all"
    log "• Nginx Reload: sudo systemctl reload nginx"
    log "• Database Access: psql -h localhost -p $POSTGRES_PORT -U win5x_user -d win5x_db"
    log "• Redis Access: redis-cli -p $REDIS_PORT -a $REDIS_PASSWORD"
    log ""
    log "${YELLOW}📊 Port Configuration:${NC}"
    log "• User Panel: $USER_PORT"
    log "• Admin Panel: $ADMIN_PORT"
    log "• Backend API: $BACKEND_PORT"
    log "• Nginx: $NGINX_PORT"
    log "• PostgreSQL: $POSTGRES_PORT"
    log "• Redis: $REDIS_PORT"
    log ""
    log "${RED}⚠️  Important Security Notes:${NC}"
    log "• Change default passwords immediately"
    log "• Update JWT secret in production"
    log "• Configure SSL certificates for HTTPS"
    log "• Review firewall rules"
    log ""
    log "${CYAN}📁 Project Location: $PROJECT_PATH${NC}"
    log "${CYAN}📄 Log File: $LOG_FILE${NC}"
    log "${CYAN}💾 Backup Directory: $BACKUP_DIR${NC}"
    log "${CYAN}===============================================${NC}"
}

# Check if project is already set up
check_existing_setup() {
    log_step "Checking for existing setup..."
    
    local existing_components=()
    
    # Check for existing database
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "win5x_db"; then
        existing_components+=("Database")
    fi
    
    # Check for existing PM2 processes
    if pm2 list | grep -q "win5x"; then
        existing_components+=("PM2 processes")
    fi
    
    # Check for existing Nginx config
    if [ -f "/etc/nginx/sites-available/win5x" ]; then
        existing_components+=("Nginx configuration")
    fi
    
    if [ ${#existing_components[@]} -gt 0 ]; then
        log_warning "Found existing setup components: ${existing_components[*]}"
        log_info "The script will attempt to update/configure existing components"
        log_info "If you want a fresh installation, please remove existing components first"
        read -p "Do you want to continue with the existing setup? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Exiting. Please clean up existing components and run again."
            exit 0
        fi
    else
        log_info "No existing setup detected, proceeding with fresh installation"
    fi
}

# Main execution
main() {
    log "${GREEN}🚀 Starting Win5x Master Setup...${NC}"
    log "${CYAN}===============================================${NC}"
    log "Log file: $LOG_FILE"
    log "Backup directory: $BACKUP_DIR"
    log ""
    
    # Pre-setup validation
    validate_system
    validate_ports
    check_existing_setup
    backup_system
    
    # Installation steps
    install_system_packages
    install_nodejs
    install_postgresql
    install_redis
    install_nginx
    
    # Project setup
    setup_project
    install_dependencies
    setup_database
    create_environment_files
    build_project
    setup_database_schema
    setup_pm2
    setup_nginx
    setup_firewall
    start_services
    
    # Post-setup validation
    perform_health_checks
    
    # Final information
    display_final_info
    
    log_success "Master setup completed successfully!"
}

# Run main function
main "$@"
