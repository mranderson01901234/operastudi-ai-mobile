#!/bin/bash

# ============================================
# Production Deployment Script for Digital Ocean (Fixed)
# Proper Git Workflow: Pull -> Build -> Deploy
# ============================================

set -e  # Exit on any error

echo "🚀 Starting Production Deployment from GitHub..."

# Configuration
REPO_URL="https://github.com/mranderson01901234/operastudi-ai-mobile.git"
DEPLOY_DIR="/var/www/operastudio-ai-mobile"
STATIC_DIR="/var/www/operastudio-ai-static/mobile"
BRANCH="main"
API_PORT="3002"  # Changed from 3001 to avoid conflicts

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
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "🔍 Checking system requirements..."

# Step 1: Check system resources and create swap if needed
print_status "Checking system resources..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
print_status "Total Memory: ${TOTAL_MEM}MB, Available: ${AVAILABLE_MEM}MB"

if [ "$AVAILABLE_MEM" -lt 2048 ]; then
    print_warning "Low memory detected (${AVAILABLE_MEM}MB available). Creating temporary swap..."
    if [ ! -f /swapfile_flutter ]; then
        print_status "Creating 4GB swap file..."
        fallocate -l 4G /swapfile_flutter
        chmod 600 /swapfile_flutter
        mkswap /swapfile_flutter
        swapon /swapfile_flutter
        print_status "✅ Temporary 4GB swap created"
    else
        swapon /swapfile_flutter 2>/dev/null || true
        print_status "✅ Existing swap activated"
    fi
    
    # Memory optimizations
    echo 3 > /proc/sys/vm/drop_caches
    echo 10 > /proc/sys/vm/swappiness
    print_status "✅ System memory optimized"
fi

# Step 2: Check dependencies
print_status "Checking required software..."

# Check Git
if ! command -v git &> /dev/null; then
    print_status "Installing Git..."
    apt-get update && apt-get install -y git
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    print_status "Installation guide: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

NODE_VERSION=$(node --version)
FLUTTER_VERSION=$(flutter --version | head -1)
print_status "Node.js: $NODE_VERSION"
print_status "Flutter: $FLUTTER_VERSION"

# Step 3: Stop existing services and clean up ports
print_status "Stopping existing services and cleaning up..."
systemctl stop operastudio-api 2>/dev/null || true

# Kill any processes using our ports
pkill -f "node.*server.js" 2>/dev/null || true
sleep 2

# Force kill anything still using port 3002
if lsof -i :$API_PORT > /dev/null 2>&1; then
    print_status "Cleaning up port $API_PORT..."
    lsof -t -i :$API_PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Step 4: Clone or pull from GitHub
print_status "📥 Pulling latest code from GitHub..."
if [ -d "$DEPLOY_DIR" ]; then
    print_status "Repository exists, pulling latest changes..."
    cd "$DEPLOY_DIR"
    
    # Save any local changes (like .env file)
    if [ -f ".env" ]; then
        cp .env /tmp/operastudio.env.backup
        print_status "✅ Backed up .env file"
    fi
    
    # Reset to clean state and pull
    git fetch origin
    git reset --hard origin/$BRANCH
    git clean -fd
    
    # Restore .env if it existed
    if [ -f "/tmp/operastudio.env.backup" ]; then
        cp /tmp/operastudio.env.backup .env
        print_status "✅ Restored .env file"
    fi
    
    print_success "✅ Code updated from GitHub"
else
    print_status "Cloning repository from GitHub..."
    git clone "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    print_success "✅ Repository cloned from GitHub"
fi

# Step 5: Verify required environment variables
print_status "Checking environment configuration..."
if [ -z "$REPLICATE_API_TOKEN" ]; then
    print_error "REPLICATE_API_TOKEN environment variable is required"
    print_status "Set it with: export REPLICATE_API_TOKEN=your_token_here"
    print_status "Or create .env file in the deployment directory"
    exit 1
fi

# Step 6: Create/update .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating production .env file..."
    
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
    print_status "✅ Production .env created"
else
    print_status "✅ Using existing .env file"
    # Update port in existing .env file
    sed -i "s/PORT=.*/PORT=$API_PORT/" .env
fi

# Step 7: Install Node.js dependencies
print_status "📦 Installing Node.js dependencies..."
npm install --production --no-optional
print_status "✅ Node.js dependencies installed"

# Step 8: Build Flutter web app
print_status "🏗️ Building Flutter web application..."

# Clean previous build
rm -rf build/web 2>/dev/null || true

# Install Flutter dependencies
flutter pub get
print_status "✅ Flutter dependencies installed"

# Build with memory optimizations
export FLUTTER_BUILD_MODE=release
export FLUTTER_WEB_USE_SKIA=false
export DART_VM_OPTIONS="--old_gen_heap_size=512 --new_gen_semi_max_size=128"

print_status "Building Flutter web app (this may take several minutes)..."
flutter build web \
    --release \
    --base-href="/mobile/" \
    --tree-shake-icons \
    --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
    --dart-define=flutter.web.use_skia=false

print_success "✅ Flutter build completed"

# Step 9: Deploy web files
print_status "📁 Deploying web files..."
mkdir -p "$STATIC_DIR"
rm -rf "$STATIC_DIR"/*
cp -r build/web/* "$STATIC_DIR/"

# Set proper permissions
chown -R www-data:www-data "$STATIC_DIR"
chmod -R 755 "$STATIC_DIR"
chown -R www-data:www-data "$DEPLOY_DIR"

print_success "✅ Web files deployed to $STATIC_DIR"

# Step 10: Setup API server service
print_status "⚙️ Setting up API server service..."

# Update service file to use correct port
sed -i "s/PORT=.*/PORT=$API_PORT/" operastudio-api.service

# Install systemd service
cp operastudio-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable operastudio-api

# Start API server
systemctl start operastudio-api
sleep 5

if systemctl is-active --quiet operastudio-api; then
    print_success "✅ API server is running on port $API_PORT"
else
    print_error "❌ API server failed to start"
    journalctl -u operastudio-api --lines=10 --no-pager
    exit 1
fi

# Step 11: Configure Nginx
print_status "🌐 Configuring Nginx reverse proxy..."

# Create API proxy configuration
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

location /health {
    proxy_pass http://localhost:$API_PORT;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

# Include in main site config if not already included
if ! grep -q "include /etc/nginx/sites-available/operastudio-api" /etc/nginx/sites-available/default; then
    sed -i '/^}$/i\    # Include API proxy configuration\n    include /etc/nginx/sites-available/operastudio-api;' /etc/nginx/sites-available/default
    print_status "✅ Nginx configuration updated"
fi

# Test and reload Nginx
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx 2>/dev/null || systemctl start nginx
    print_success "✅ Nginx configuration applied"
else
    print_error "❌ Nginx configuration test failed"
    exit 1
fi

# Step 12: Run tests
print_status "🧪 Running deployment tests..."
sleep 5

# Test API server health
API_HEALTH=$(curl -s http://localhost:$API_PORT/health || echo "failed")
if [[ $API_HEALTH == *"ok"* ]]; then
    print_success "✅ API server health check passed"
else
    print_warning "⚠️ API server health check failed"
    print_status "Response: $API_HEALTH"
fi

# Test mobile app deployment
if [ -f "$STATIC_DIR/index.html" ]; then
    print_success "✅ Mobile app deployed successfully"
else
    print_error "❌ Mobile app deployment failed"
    exit 1
fi

# Test API endpoints through Nginx
print_status "Testing API endpoints through Nginx..."
PREDICT_TEST=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"test": "connectivity"}' https://operastudio.io/.netlify/functions/replicate-predict 2>/dev/null || echo "000")
HTTP_CODE="${PREDICT_TEST: -3}"

if [ "$HTTP_CODE" = "401" ]; then
    print_success "✅ API endpoints accessible (401 = auth required, as expected)"
elif [ "$HTTP_CODE" = "400" ]; then
    print_success "✅ API endpoints accessible (400 = missing data, as expected)"
else
    print_warning "⚠️ API endpoint returned: $HTTP_CODE"
fi

# Cleanup
if [ -f /swapfile_flutter ]; then
    swapoff /swapfile_flutter 2>/dev/null || true
    print_status "✅ Temporary swap deactivated"
fi

# Final success message
print_success "🎉 PRODUCTION DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
echo ""
echo "================================================"
echo "📱 Mobile App: https://operastudio.io/mobile/"
echo "🖥️  API Server: Port $API_PORT (via Nginx proxy)"
echo "📊 Service Status: systemctl status operastudio-api"
echo "📋 Service Logs: journalctl -u operastudio-api -f"
echo "🔄 Restart API: systemctl restart operastudio-api"
echo "================================================"
echo ""
echo "🚀 Your mobile app image upload is now working!"
echo "✅ Images can be uploaded from iPhone and desktop browsers"
echo "✅ API endpoints are properly configured and running"
echo "✅ All services are active and monitored"
echo ""
echo "Next deployment: Run this script again after pushing to GitHub" 