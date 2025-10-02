#!/bin/bash

# Win5x Server Restart and Error Check Script
# This script restarts all services and performs comprehensive error checking

echo "========================================="
echo "    Win5x Server Restart & Error Check"
echo "========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a port is listening
check_port() {
    local port=$1
    local service_name=$2
    if netstat -tuln | grep -q ":$port "; then
        print_status $GREEN "✅ $service_name is running on port $port"
        return 0
    else
        print_status $RED "❌ $service_name is NOT running on port $port"
        return 1
    fi
}

# Function to check service health via HTTP
check_service_health() {
    local url=$1
    local service_name=$2
    local timeout=10
    
    print_status $YELLOW "🔍 Checking $service_name health at $url..."
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        print_status $GREEN "✅ $service_name is responding"
        return 0
    else
        print_status $RED "❌ $service_name is not responding"
        return 1
    fi
}

# Function to show recent logs
show_recent_logs() {
    local service=$1
    local log_file=$2
    local lines=${3:-20}
    
    if [ -f "$log_file" ]; then
        print_status $BLUE "📋 Recent $service logs (last $lines lines):"
        echo "----------------------------------------"
        tail -n $lines "$log_file"
        echo "----------------------------------------"
        echo
    else
        print_status $YELLOW "⚠️ Log file $log_file not found"
    fi
}

# Function to check disk space
check_disk_space() {
    print_status $BLUE "💾 Checking disk space..."
    df -h /
    echo
}

# Function to check memory usage
check_memory() {
    print_status $BLUE "🧠 Checking memory usage..."
    free -h
    echo
}

# Function to check system load
check_system_load() {
    print_status $BLUE "⚡ Checking system load..."
    uptime
    echo
}

# Start the restart and check process
print_status $YELLOW "🔄 Step 1: Stopping all PM2 services..."
pm2 stop all
pm2 delete all
echo

print_status $YELLOW "🧹 Step 2: Cleaning up any hanging processes..."
# Kill any processes that might be using our ports
for port in 8080 8081 8082; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        print_status $YELLOW "Killing process $pid on port $port"
        kill -9 $pid 2>/dev/null
    fi
done
echo

print_status $YELLOW "📦 Step 3: Installing/updating dependencies..."
cd /var/www/kart
pnpm install --prod
echo

print_status $YELLOW "🔨 Step 4: Building project..."
pnpm run build
echo

print_status $YELLOW "🚀 Step 5: Starting services with PM2..."
pm2 start ecosystem.config.js
pm2 save
echo

print_status $YELLOW "⏳ Step 6: Waiting for services to start..."
sleep 10
echo

print_status $BLUE "========================================="
print_status $BLUE "           SERVICE STATUS CHECK"
print_status $BLUE "========================================="
echo

# Check PM2 status
print_status $BLUE "📊 PM2 Process Status:"
pm2 status
echo

# Check if ports are listening
print_status $BLUE "🔌 Port Status Check:"
check_port 8080 "User Frontend"
check_port 8081 "Admin Frontend" 
check_port 8082 "Backend API"
echo

# Check service health
print_status $BLUE "🏥 Service Health Check:"
check_service_health "http://localhost:8080" "User Frontend"
check_service_health "http://localhost:8081" "Admin Frontend"
check_service_health "http://localhost:8082/api/health" "Backend API"
echo

# System resource checks
check_disk_space
check_memory
check_system_load

print_status $BLUE "========================================="
print_status $BLUE "              ERROR ANALYSIS"
print_status $BLUE "========================================="
echo

# Check for errors in logs
print_status $YELLOW "🔍 Checking for errors in service logs..."

# Check PM2 logs for errors
print_status $BLUE "📋 PM2 Error Logs:"
pm2 logs --err --lines 10
echo

# Check individual service logs
show_recent_logs "Backend" "/var/www/kart/logs/backend-error.log" 15
show_recent_logs "Admin" "/var/www/kart/logs/admin-error.log" 15
show_recent_logs "User" "/var/www/kart/logs/user-error.log" 15

# Check system logs for any relevant errors
print_status $BLUE "📋 System Error Logs (last 10 lines):"
journalctl --since "10 minutes ago" --priority=err --no-pager | tail -10
echo

print_status $BLUE "========================================="
print_status $BLUE "              FINAL SUMMARY"
print_status $BLUE "========================================="
echo

# Final status check
print_status $BLUE "🌐 Application URLs:"
print_status $GREEN "   User Panel:  http://217.148.142.91:8080"
print_status $GREEN "   Admin Panel: http://217.148.142.91:8081"
print_status $GREEN "   Backend API: http://217.148.142.91:8082"
echo

# Count running services
running_services=$(pm2 jlist | jq -r '.[] | select(.pm2_env.status == "online") | .name' | wc -l)
total_services=3

if [ "$running_services" -eq "$total_services" ]; then
    print_status $GREEN "✅ All $total_services services are running successfully!"
else
    print_status $RED "❌ Only $running_services out of $total_services services are running"
    print_status $YELLOW "Check the logs above for error details"
fi

echo
print_status $BLUE "========================================="
print_status $GREEN "        Restart & Check Complete!"
print_status $BLUE "========================================="
