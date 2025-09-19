#!/bin/bash

# ============================================
# Mobile App + API Server Deployment Script for Digital Ocean
# ============================================

set -e  # Exit on any error

echo "🚀 Starting Mobile App + API Server Deployment..."

# Configuration
REPO_URL="https://github.com/mranderson01901234/operastudi-ai-mobile.git"
DEPLOY_DIR="/var/www/operastudio-ai-mobile"
STATIC_DIR="/var/www/operastudio-ai-static/mobile"
BRANCH="main"
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "Running as root - Flutter recommends running without superuser privileges"
   print_status "Continuing with deployment (required for file permissions)..."
else
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Step 1: Clone or pull repository
print_status "Setting up repository..."
if [ -d "$DEPLOY_DIR" ]; then
    print_status "Repository exists, pulling latest changes..."
    cd "$DEPLOY_DIR"
    git pull origin "$BRANCH"
else
    print_status "Cloning repository..."
    git clone "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

# Step 2: Check system resources and Flutter installation
print_status "Checking system resources..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
print_status "Total Memory: ${TOTAL_MEM}MB, Available: ${AVAILABLE_MEM}MB"

if [ "$AVAILABLE_MEM" -lt 2048 ]; then
    print_warning "Low memory detected (${AVAILABLE_MEM}MB available). Creating temporary swap..."
    # Create 4GB swap file for better performance
    if [ ! -f /swapfile_flutter ]; then
        print_status "Creating 4GB swap file (this may take a moment)..."
        fallocate -l 4G /swapfile_flutter
        chmod 600 /swapfile_flutter
        mkswap /swapfile_flutter
        swapon /swapfile_flutter
        print_status "✅ Temporary 4GB swap created"
    else
        swapon /swapfile_flutter 2>/dev/null || true
        print_status "✅ Existing swap activated"
    fi
    
    # Additional memory optimizations
    print_status "Applying memory optimizations..."
    echo 3 > /proc/sys/vm/drop_caches  # Clear system caches
    echo 10 > /proc/sys/vm/swappiness  # Prefer RAM over swap
    print_status "✅ System caches cleared and swappiness optimized"
fi

print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    print_status "Installation guide: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

# Step 3: Check Node.js installation
print_status "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    print_status "✅ Node.js installed"
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Step 4: Create production .env file for web build
print_status "Creating production environment configuration..."

# Check for required environment variables
if [ -z "$REPLICATE_API_TOKEN" ]; then
    print_error "REPLICATE_API_TOKEN environment variable is required"
    print_status "Set it with: export REPLICATE_API_TOKEN=your_token_here"
    print_status "Or copy your .env file to server and run: source .env"
    exit 1
fi

# Use defaults for Supabase if not set
SUPABASE_URL_DEFAULT="https://rnygtixdxbnflxflzpyr.supabase.co"
SUPABASE_ANON_KEY_DEFAULT="sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3"

cat > .env << EOF
ENVIRONMENT=prod
DEBUG_MODE=false
LOG_LEVEL=info
API_BASE_URL=https://operastudio.io
WEB_API_ENDPOINT=https://operastudio.io/.netlify/functions
SUPABASE_URL=\${SUPABASE_URL:-$SUPABASE_URL_DEFAULT}
SUPABASE_ANON_KEY=\${SUPABASE_ANON_KEY:-$SUPABASE_ANON_KEY_DEFAULT}
REPLICATE_API_TOKEN=$REPLICATE_API_TOKEN
REPLICATE_MODEL_ID=mranderson01901234/my-app-scunetrepliactemodel
REPLICATE_MODEL_VERSION=df9a3c1d
PORT=$API_PORT
NODE_ENV=production
EOF
print_status "✅ Production .env created with environment variables"

# Step 5: Install Node.js dependencies for API server
print_status "Installing Node.js dependencies..."
if [ -f "package.json" ]; then
    npm install --production
    print_status "✅ Node.js dependencies installed"
else
    print_error "package.json not found - API server setup may fail"
fi

# Step 6: Clean and install Flutter dependencies
print_status "Cleaning Flutter cache and installing dependencies..."
if [[ $EUID -eq 0 ]]; then
    # Run as a regular user to avoid Flutter root warnings
    if [ -n "$SUDO_USER" ]; then
        sudo -u $SUDO_USER flutter clean
        sudo -u $SUDO_USER flutter pub get
    else
        # If no SUDO_USER, try to find a non-root user or skip clean
        print_warning "No SUDO_USER found, skipping flutter clean to avoid root issues"
        flutter pub get
    fi
else
    flutter clean
    flutter pub get
fi

# Step 7: Build web app with aggressive memory optimizations
print_status "Building Flutter web app with aggressive memory optimizations..."

# Set memory-friendly environment variables for the build
export FLUTTER_BUILD_MODE=release
export FLUTTER_WEB_USE_SKIA=false
export DART_VM_OPTIONS="--old_gen_heap_size=512"

if [[ $EUID -eq 0 ]]; then
    # Run as a regular user to avoid Flutter root warnings
    if [ -n "$SUDO_USER" ]; then
        sudo -u $SUDO_USER -E flutter build web \
            --release \
            --base-href="/mobile/" \
            --tree-shake-icons \
            --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
            --dart-define=flutter.web.use_skia=false
    else
        # If no SUDO_USER, build as root (not ideal but necessary)
        print_warning "No SUDO_USER found, building as root (not recommended)"
        flutter build web \
            --release \
            --base-href="/mobile/" \
            --tree-shake-icons \
            --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
            --dart-define=flutter.web.use_skia=false
    fi
else
    flutter build web \
        --release \
        --base-href="/mobile/" \
        --tree-shake-icons \
        --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
        --dart-define=flutter.web.use_skia=false
fi

print_status "✅ Build completed with memory optimizations"

# Step 8: Create mobile directory if it doesn't exist
print_status "Setting up mobile directory..."
mkdir -p "$STATIC_DIR"

# Step 9: Copy built files to static directory
print_status "Deploying files to static directory..."
cp -r build/web/* "$STATIC_DIR/"

# Step 10: Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data "$STATIC_DIR"
chmod -R 755 "$STATIC_DIR"
chown -R www-data:www-data "$DEPLOY_DIR"

# Step 11: Setup API server as systemd service
print_status "Setting up API server service..."

# Stop existing service if running
systemctl stop operastudio-api 2>/dev/null || true

# Copy service file
if [ -f "operastudio-api.service" ]; then
    cp operastudio-api.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable operastudio-api
    print_status "✅ API server service configured"
else
    print_warning "Service file not found - creating basic service"
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
fi

# Step 12: Start API server
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

# Step 13: Configure Nginx reverse proxy
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
EOF

# Include the API configuration in the main site config
if ! grep -q "include /etc/nginx/sites-available/operastudio-api" /etc/nginx/sites-available/default; then
    # Add the include line before the last closing brace
    sed -i '/^}$/i\    # Include API proxy configuration\n    include /etc/nginx/sites-available/operastudio-api;' /etc/nginx/sites-available/default
    print_status "✅ Nginx configuration updated with API proxy"
else
    print_status "✅ Nginx API configuration already included"
fi

# Step 14: Verify deployment
print_status "Verifying deployment..."
if [ -f "$STATIC_DIR/index.html" ]; then
    print_success "✅ Mobile app deployed successfully!"
    print_success "📱 Mobile app available at: https://operastudio.io/mobile/"
    
    # Show file structure
    print_status "Deployed files:"
    ls -la "$STATIC_DIR" | head -10
else
    print_error "❌ Deployment failed - index.html not found"
    exit 1
fi

# Step 15: Test API server
print_status "Testing API server..."
API_HEALTH=$(curl -s http://localhost:$API_PORT/health || echo "failed")
if [[ $API_HEALTH == *"ok"* ]]; then
    print_success "✅ API server health check passed"
else
    print_warning "⚠️ API server health check failed - may need manual verification"
fi

# Step 16: Test web server configuration
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

# Cleanup temporary swap if we created it
if [ -f /swapfile_flutter ]; then
    print_status "Cleaning up temporary swap..."
    swapoff /swapfile_flutter 2>/dev/null || true
    # Don't remove the file, keep it for future builds
    print_status "✅ Swap deactivated (keeping file for future builds)"
fi

print_success "🎉 Mobile app + API server deployment completed!"
print_status "Services running:"
print_status "1. Mobile App: https://operastudio.io/mobile/"
print_status "2. API Server: http://localhost:$API_PORT (proxied through Nginx)"
print_status ""
print_status "API Endpoints available:"
print_status "- POST https://operastudio.io/.netlify/functions/replicate-predict"
print_status "- GET  https://operastudio.io/.netlify/functions/replicate-status/:id"
print_status "- POST https://operastudio.io/.netlify/functions/api-v1-enhance-general"
print_status ""
print_status "Next steps:"
print_status "1. Test the mobile app at https://operastudio.io/mobile/"
print_status "2. Check API server logs: journalctl -u operastudio-api -f"
print_status "3. Monitor service status: systemctl status operastudio-api"

echo ""
echo "================================================"
echo "🚀 Deployment Summary:"
echo "📁 Source: $REPO_URL"
echo "📂 Deploy Dir: $DEPLOY_DIR" 
echo "🌐 Static Dir: $STATIC_DIR"
echo "🔗 Mobile URL: https://operastudio.io/mobile/"
echo "🖥️  API Server: Port $API_PORT"
echo "================================================" 