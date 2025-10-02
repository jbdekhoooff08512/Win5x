#!/bin/bash

# Win5x Complete Cleanup Script
# This script removes everything related to Win5x installation
# WARNING: This will delete ALL data and configurations!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="${PROJECT_PATH:-/var/www/kart}"
DB_NAME="win5x_db"
DB_USER="win5x_user"

echo -e "${RED}⚠️  WARNING: This script will DELETE EVERYTHING!${NC}"
echo -e "${RED}This includes:${NC}"
echo -e "${RED}• All project files${NC}"
echo -e "${RED}• Database and data${NC}"
echo -e "${RED}• PM2 processes${NC}"
echo -e "${RED}• Nginx configuration${NC}"
echo -e "${RED}• Redis data${NC}"
echo -e "${RED}• All logs${NC}"
echo ""
read -p "Are you sure you want to continue? Type 'DELETE' to confirm: " confirmation

if [ "$confirmation" != "DELETE" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${RED}🚨 Starting complete cleanup...${NC}"

# Function to run command with error handling
run_command() {
    local command="$1"
    local description="$2"
    
    echo -e "${YELLOW}🔄 $description${NC}"
    if eval "$command" 2>/dev/null; then
        echo -e "${GREEN}✅ $description completed${NC}"
    else
        echo -e "${YELLOW}⚠️  $description - Some items may not exist${NC}"
    fi
}

# Stop and delete PM2 processes
echo -e "${BLUE}🔄 Stopping PM2 processes...${NC}"
run_command "pm2 delete all" "PM2 processes deletion"
run_command "pm2 kill" "PM2 daemon kill"

# Stop services
echo -e "${BLUE}🔄 Stopping services...${NC}"
run_command "sudo systemctl stop nginx" "Nginx service stop"
run_command "sudo systemctl stop redis-server" "Redis service stop"
run_command "sudo systemctl stop postgresql" "PostgreSQL service stop"

# Remove Nginx configuration
echo -e "${BLUE}🔄 Removing Nginx configuration...${NC}"
run_command "sudo rm -f /etc/nginx/sites-available/win5x" "Nginx config removal"
run_command "sudo rm -f /etc/nginx/sites-enabled/win5x" "Nginx site removal"
run_command "sudo systemctl start nginx" "Nginx service restart"

# Remove PostgreSQL database and user
echo -e "${BLUE}🔄 Removing PostgreSQL database and user...${NC}"
run_command "sudo -u postgres psql -c \"DROP DATABASE IF EXISTS $DB_NAME;\"" "Database deletion"
run_command "sudo -u postgres psql -c \"DROP USER IF EXISTS $DB_USER;\"" "Database user deletion"

# Clear Redis data
echo -e "${BLUE}🔄 Clearing Redis data...${NC}"
run_command "redis-cli FLUSHALL" "Redis data clear"

# Remove project directory
echo -e "${BLUE}🔄 Removing project directory...${NC}"
run_command "sudo rm -rf $PROJECT_PATH" "Project directory removal"

# Remove logs
echo -e "${BLUE}🔄 Removing logs...${NC}"
run_command "sudo rm -rf /var/log/win5x*" "Win5x logs removal"
run_command "sudo rm -rf /tmp/win5x-*" "Temporary files removal"

# Remove PM2 configuration
echo -e "${BLUE}🔄 Removing PM2 configuration...${NC}"
run_command "rm -rf ~/.pm2" "PM2 configuration removal"

# Remove systemd service
echo -e "${BLUE}🔄 Removing systemd service...${NC}"
run_command "sudo rm -f /etc/systemd/system/pm2-win5x.service" "PM2 systemd service removal"
run_command "sudo systemctl daemon-reload" "Systemd daemon reload"

# Remove firewall rules (optional)
echo -e "${BLUE}🔄 Removing firewall rules...${NC}"
run_command "sudo ufw delete allow 8080" "User panel firewall rule removal"
run_command "sudo ufw delete allow 8081" "Admin panel firewall rule removal"
run_command "sudo ufw delete allow 8082" "Backend API firewall rule removal"

# Remove Redis configuration backup
echo -e "${BLUE}🔄 Removing Redis configuration backup...${NC}"
run_command "sudo rm -f /etc/redis/redis.conf.backup" "Redis config backup removal"

# Remove any remaining processes
echo -e "${BLUE}🔄 Killing any remaining processes...${NC}"
run_command "sudo pkill -f 'win5x'" "Win5x processes kill"
run_command "sudo pkill -f 'node.*server.js'" "Node server processes kill"

# Clean package cache
echo -e "${BLUE}🔄 Cleaning package cache...${NC}"
run_command "sudo apt autoremove -y" "Package autoremove"
run_command "sudo apt autoclean" "Package cache clean"

# Remove any remaining files
echo -e "${BLUE}🔄 Removing any remaining files...${NC}"
run_command "sudo find /var/log -name '*win5x*' -delete" "Log files cleanup"
run_command "sudo find /tmp -name '*win5x*' -delete" "Temporary files cleanup"
run_command "sudo find /home -name '*win5x*' -delete" "Home directory cleanup"

# Restart services
echo -e "${BLUE}🔄 Restarting services...${NC}"
run_command "sudo systemctl start postgresql" "PostgreSQL service start"
run_command "sudo systemctl start redis-server" "Redis service start"
run_command "sudo systemctl start nginx" "Nginx service start"

# Final cleanup check
echo -e "${BLUE}🔄 Final cleanup check...${NC}"
echo -e "${CYAN}Checking for remaining files...${NC}"

# Check for remaining files
if [ -d "$PROJECT_PATH" ]; then
    echo -e "${RED}❌ Project directory still exists: $PROJECT_PATH${NC}"
else
    echo -e "${GREEN}✅ Project directory removed${NC}"
fi

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo -e "${RED}❌ Database still exists: $DB_NAME${NC}"
else
    echo -e "${GREEN}✅ Database removed${NC}"
fi

if pm2 list | grep -q "win5x"; then
    echo -e "${RED}❌ PM2 processes still exist${NC}"
else
    echo -e "${GREEN}✅ PM2 processes removed${NC}"
fi

if [ -f "/etc/nginx/sites-available/win5x" ]; then
    echo -e "${RED}❌ Nginx configuration still exists${NC}"
else
    echo -e "${GREEN}✅ Nginx configuration removed${NC}"
fi

# Display final information
echo ""
echo -e "${CYAN}===============================================${NC}"
echo -e "${GREEN}🎉 Win5x Complete Cleanup Finished!${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo -e "${YELLOW}📋 Cleanup Summary:${NC}"
echo -e "• PM2 processes: Deleted"
echo -e "• Database: Deleted"
echo -e "• Project files: Deleted"
echo -e "• Nginx configuration: Removed"
echo -e "• Redis data: Cleared"
echo -e "• Logs: Removed"
echo -e "• Services: Restarted"
echo ""
echo -e "${YELLOW}🔧 Services Status:${NC}"
echo -e "• PostgreSQL: $(sudo systemctl is-active postgresql)"
echo -e "• Redis: $(sudo systemctl is-active redis-server)"
echo -e "• Nginx: $(sudo systemctl is-active nginx)"
echo ""
echo -e "${RED}⚠️  Important Notes:${NC}"
echo -e "• All Win5x data has been permanently deleted"
echo -e "• Services have been restarted"
echo -e "• System is clean and ready for fresh installation"
echo ""
echo -e "${CYAN}===============================================${NC}"