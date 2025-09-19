#!/bin/bash

echo "🔧 Fixing API Server on Digital Ocean..."

# Kill all node processes
pkill -f node
sleep 3

# Stop the systemd service
systemctl stop operastudio-api
sleep 2

# Check if port is free
if lsof -i :3001 > /dev/null; then
    echo "❌ Port 3001 still in use, killing remaining processes..."
    lsof -t -i :3001 | xargs kill -9
    sleep 2
fi

# Start the service
systemctl start operastudio-api
sleep 3

# Check status
if systemctl is-active --quiet operastudio-api; then
    echo "✅ API Server is running"
    curl -s http://localhost:3001/health
else
    echo "❌ API Server failed to start"
    journalctl -u operastudio-api --lines=5 --no-pager
fi 