#!/bin/bash
# Check if port is in use and kill if necessary
PORT=8081
if lsof -i :$PORT > /dev/null 2>&1; then
    echo "Port $PORT is in use. Killing processes..."
    pkill -f flutter
    sleep 2
fi
echo "Starting Flutter server on port $PORT..."
CHROME_EXECUTABLE=/usr/bin/chromium flutter run -d web-server --web-hostname 0.0.0.0 --web-port $PORT
