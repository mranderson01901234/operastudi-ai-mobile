#!/bin/bash

# ============================================
# Simplified Mobile App + API Server Deployment Script
# ============================================

set -e  # Exit on any error

echo "🚀 Starting Simplified Mobile App + API Server Deployment..."

# Configuration
DEPLOY_DIR="/var/www/operastudio-ai-mobile"
STATIC_DIR="/var/www/operastudio-ai-static/mobile"
API_PORT="3001"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Current working directory: $(pwd)"

# Step 1: Check Node.js installation
print_status "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    print_status "✅ Node.js installed"
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Step 2: Install Node.js dependencies for API server
print_status "Installing Node.js dependencies..."
if [ -f "package.json" ]; then
    npm install --production --no-optional
    print_status "✅ Node.js dependencies installed"
else
    print_error "package.json not found - API server setup may fail"
fi

# Step 3: Skip Flutter clean due to memory constraints, just get dependencies
print_status "Installing Flutter dependencies (skipping clean due to memory constraints)..."
flutter pub get
print_status "✅ Flutter dependencies installed"

# Step 4: Build web app with maximum memory optimizations
print_status "Building Flutter web app with maximum memory optimizations..."

# Set aggressive memory limits
export FLUTTER_BUILD_MODE=release
export FLUTTER_WEB_USE_SKIA=false
export DART_VM_OPTIONS="--old_gen_heap_size=256 --new_gen_semi_max_size=64"

print_warning "Building as root due to memory constraints (not recommended for production)"
flutter build web \
    --release \
    --base-href="/mobile/" \
    --tree-shake-icons \
    --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
    --dart-define=flutter.web.use_skia=false \
    --no-sound-null-safety 2>/dev/null || flutter build web \
    --release \
    --base-href="/mobile/" \
    --tree-shake-icons \
    --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
    --dart-define=flutter.web.use_skia=false

print_status "✅ Build completed"

# Step 5: Create mobile directory if it doesn't exist
print_status "Setting up mobile directory..."
mkdir -p "$STATIC_DIR"

# Step 6: Copy built files to static directory
print_status "Deploying files to static directory..."
cp -r build/web/* "$STATIC_DIR/"

# Step 7: Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data "$STATIC_DIR"
chmod -R 755 "$STATIC_DIR"
chown -R www-data:www-data "$DEPLOY_DIR"

# Step 8: Setup API server as systemd service
print_status "Setting up API server service..."

# Stop existing service if running
systemctl stop operastudio-api 2>/dev/null || true

# Create service file
cat > /etc/systemd/system/operastudio-api.service << EOF
[Unit]
Description=Opera Studio API Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$API_PORT
EnvironmentFile=$DEPLOY_DIR/.env

StandardOutput=journal
StandardError=journal
SyslogIdentifier=operastudio-api

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable operastudio-api
print_status "✅ API server service created and enabled"

# Step 9: Start API server
print_status "Starting API server..."
systemctl start operastudio-api
sleep 3

# Check if service is running
if systemctl is-active --quiet operastudio-api; then
    print_success "✅ API server is running on port $API_PORT"
else
    print_error "❌ API server failed to start"
    print_status "Checking service logs..."
    journalctl -u operastudio-api --lines=10 --no-pager
    exit 1
fi

# Step 10: Configure Nginx reverse proxy
print_status "Configuring Nginx reverse proxy..."

# Create Nginx configuration for API endpoints
cat > /etc/nginx/sites-available/operastudio-api << EOF
# API server proxy configuration
location /.netlify/functions/ {
    proxy_pass http://localhost:$API_PORT;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;
    
    # CORS headers
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
    
    # Handle preflight OPTIONS requests
    if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }
}

# Health check endpoint
location /health {
    proxy_pass http://localhost:$API_PORT;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

# Include the API configuration in the main site config
if ! grep -q "include /etc/nginx/sites-available/operastudio-api" /etc/nginx/sites-available/default; then
    # Add the include line before the last closing brace
    sed -i '/^}$/i\    # Include API proxy configuration\n    include /etc/nginx/sites-available/operastudio-api;' /etc/nginx/sites-available/default
    print_status "✅ Nginx configuration updated with API proxy"
else
    print_status "✅ Nginx API configuration already included"
fi

# Step 11: Verify deployment
print_status "Verifying deployment..."
if [ -f "$STATIC_DIR/index.html" ]; then
    print_success "✅ Mobile app deployed successfully!"
    print_success "📱 Mobile app available at: https://operastudio.io/mobile/"
    
    # Show file structure
    print_status "Deployed files:"
    ls -la "$STATIC_DIR" | head -5
else
    print_error "❌ Deployment failed - index.html not found"
    exit 1
fi

# Step 12: Test API server
print_status "Testing API server..."
API_HEALTH=$(curl -s http://localhost:$API_PORT/health || echo "failed")
if [[ $API_HEALTH == *"ok"* ]]; then
    print_success "✅ API server health check passed"
else
    print_warning "⚠️ API server health check failed - checking logs..."
    journalctl -u operastudio-api --lines=5 --no-pager
fi

# Step 13: Test web server configuration
print_status "Testing Nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    print_success "✅ Nginx configuration is valid"
    print_status "Reloading Nginx..."
    systemctl reload nginx
    print_success "✅ Nginx reloaded successfully"
else
    print_warning "⚠️ Nginx configuration test failed - please check manually"
fi

print_success "🎉 Simplified deployment completed!"
print_status "Services running:"
print_status "1. Mobile App: https://operastudio.io/mobile/"
print_status "2. API Server: http://localhost:$API_PORT (proxied through Nginx)"
print_status ""
print_status "API Endpoints available:"
print_status "- POST https://operastudio.io/.netlify/functions/replicate-predict"
print_status "- GET  https://operastudio.io/.netlify/functions/replicate-status/:id"
print_status "- POST https://operastudio.io/.netlify/functions/api-v1-enhance-general"
print_status ""
print_status "To monitor API server: journalctl -u operastudio-api -f"
print_status "To restart API server: systemctl restart operastudio-api"

echo ""
echo "================================================"
echo "🚀 Deployment Summary:"
echo "📂 Deploy Dir: $DEPLOY_DIR" 
echo "🌐 Static Dir: $STATIC_DIR"
echo "🔗 Mobile URL: https://operastudio.io/mobile/"
echo "🖥️  API Server: Port $API_PORT"
echo "================================================" 