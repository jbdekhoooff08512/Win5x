# Win5x Complete Cleanup Script (PowerShell)
# This script removes everything related to Win5x installation
# WARNING: This will delete ALL data and configurations!

param(
    [string]$ProjectPath = "/var/www/win5x",
    [string]$DbName = "win5x_db",
    [string]$DbUser = "win5x_user"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

Write-Host "⚠️  WARNING: This script will DELETE EVERYTHING!" -ForegroundColor $Red
Write-Host "This includes:" -ForegroundColor $Red
Write-Host "• All project files" -ForegroundColor $Red
Write-Host "• Database and data" -ForegroundColor $Red
Write-Host "• PM2 processes" -ForegroundColor $Red
Write-Host "• Nginx configuration" -ForegroundColor $Red
Write-Host "• Redis data" -ForegroundColor $Red
Write-Host "• All logs" -ForegroundColor $Red
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? Type 'DELETE' to confirm"

if ($confirmation -ne "DELETE") {
    Write-Host "Cleanup cancelled." -ForegroundColor $Yellow
    exit 0
}

Write-Host "🚨 Starting complete cleanup..." -ForegroundColor $Red

# Function to run command with error handling
function Invoke-CleanupCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔄 $Description" -ForegroundColor $Yellow
    try {
        Invoke-Expression $Command | Out-Null
        Write-Host "✅ $Description completed" -ForegroundColor $Green
    }
    catch {
        Write-Host "⚠️  $Description - Some items may not exist" -ForegroundColor $Yellow
    }
}

# Stop and delete PM2 processes
Write-Host "🔄 Stopping PM2 processes..." -ForegroundColor $Blue
Invoke-CleanupCommand "pm2 delete all" "PM2 processes deletion"
Invoke-CleanupCommand "pm2 kill" "PM2 daemon kill"

# Stop services
Write-Host "🔄 Stopping services..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo systemctl stop nginx" "Nginx service stop"
Invoke-CleanupCommand "sudo systemctl stop redis-server" "Redis service stop"
Invoke-CleanupCommand "sudo systemctl stop postgresql" "PostgreSQL service stop"

# Remove Nginx configuration
Write-Host "🔄 Removing Nginx configuration..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo rm -f /etc/nginx/sites-available/win5x" "Nginx config removal"
Invoke-CleanupCommand "sudo rm -f /etc/nginx/sites-enabled/win5x" "Nginx site removal"
Invoke-CleanupCommand "sudo systemctl start nginx" "Nginx service restart"

# Remove PostgreSQL database and user
Write-Host "🔄 Removing PostgreSQL database and user..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo -u postgres psql -c `"DROP DATABASE IF EXISTS $DbName;`"" "Database deletion"
Invoke-CleanupCommand "sudo -u postgres psql -c `"DROP USER IF EXISTS $DbUser;`"" "Database user deletion"

# Clear Redis data
Write-Host "🔄 Clearing Redis data..." -ForegroundColor $Blue
Invoke-CleanupCommand "redis-cli FLUSHALL" "Redis data clear"

# Remove project directory
Write-Host "🔄 Removing project directory..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo rm -rf $ProjectPath" "Project directory removal"

# Remove logs
Write-Host "🔄 Removing logs..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo rm -rf /var/log/win5x*" "Win5x logs removal"
Invoke-CleanupCommand "sudo rm -rf /tmp/win5x-*" "Temporary files removal"

# Remove PM2 configuration
Write-Host "🔄 Removing PM2 configuration..." -ForegroundColor $Blue
Invoke-CleanupCommand "rm -rf ~/.pm2" "PM2 configuration removal"

# Remove systemd service
Write-Host "🔄 Removing systemd service..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo rm -f /etc/systemd/system/pm2-win5x.service" "PM2 systemd service removal"
Invoke-CleanupCommand "sudo systemctl daemon-reload" "Systemd daemon reload"

# Remove firewall rules
Write-Host "🔄 Removing firewall rules..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo ufw delete allow 8080" "User panel firewall rule removal"
Invoke-CleanupCommand "sudo ufw delete allow 8081" "Admin panel firewall rule removal"
Invoke-CleanupCommand "sudo ufw delete allow 8082" "Backend API firewall rule removal"

# Remove Redis configuration backup
Write-Host "🔄 Removing Redis configuration backup..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo rm -f /etc/redis/redis.conf.backup" "Redis config backup removal"

# Remove any remaining processes
Write-Host "🔄 Killing any remaining processes..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo pkill -f 'win5x'" "Win5x processes kill"
Invoke-CleanupCommand "sudo pkill -f 'node.*server.js'" "Node server processes kill"

# Clean package cache
Write-Host "🔄 Cleaning package cache..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo apt autoremove -y" "Package autoremove"
Invoke-CleanupCommand "sudo apt autoclean" "Package cache clean"

# Remove any remaining files
Write-Host "🔄 Removing any remaining files..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo find /var/log -name '*win5x*' -delete" "Log files cleanup"
Invoke-CleanupCommand "sudo find /tmp -name '*win5x*' -delete" "Temporary files cleanup"
Invoke-CleanupCommand "sudo find /home -name '*win5x*' -delete" "Home directory cleanup"

# Restart services
Write-Host "🔄 Restarting services..." -ForegroundColor $Blue
Invoke-CleanupCommand "sudo systemctl start postgresql" "PostgreSQL service start"
Invoke-CleanupCommand "sudo systemctl start redis-server" "Redis service start"
Invoke-CleanupCommand "sudo systemctl start nginx" "Nginx service start"

# Final cleanup check
Write-Host "🔄 Final cleanup check..." -ForegroundColor $Blue
Write-Host "Checking for remaining files..." -ForegroundColor $Cyan

# Check for remaining files
if (Test-Path $ProjectPath) {
    Write-Host "❌ Project directory still exists: $ProjectPath" -ForegroundColor $Red
} else {
    Write-Host "✅ Project directory removed" -ForegroundColor $Green
}

# Display final information
Write-Host ""
Write-Host "===============================================" -ForegroundColor $Cyan
Write-Host "🎉 Win5x Complete Cleanup Finished!" -ForegroundColor $Green
Write-Host "===============================================" -ForegroundColor $Cyan
Write-Host ""
Write-Host "📋 Cleanup Summary:" -ForegroundColor $Yellow
Write-Host "• PM2 processes: Deleted"
Write-Host "• Database: Deleted"
Write-Host "• Project files: Deleted"
Write-Host "• Nginx configuration: Removed"
Write-Host "• Redis data: Cleared"
Write-Host "• Logs: Removed"
Write-Host "• Services: Restarted"
Write-Host ""
Write-Host "🔧 Services Status:" -ForegroundColor $Yellow
Write-Host "• PostgreSQL: $(sudo systemctl is-active postgresql)"
Write-Host "• Redis: $(sudo systemctl is-active redis-server)"
Write-Host "• Nginx: $(sudo systemctl is-active nginx)"
Write-Host ""
Write-Host "⚠️  Important Notes:" -ForegroundColor $Red
Write-Host "• All Win5x data has been permanently deleted"
Write-Host "• Services have been restarted"
Write-Host "• System is clean and ready for fresh installation"
Write-Host ""
Write-Host "===============================================" -ForegroundColor $Cyan
