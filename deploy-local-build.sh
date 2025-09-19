#!/bin/bash

# ============================================
# Local Build + Digital Ocean Deploy Script
# Build locally (fast) -> Deploy to server (fast)
# ============================================

set -e

# Configuration
SERVER_IP="129.212.132.210"
SERVER_USER="root"
DEPLOY_DIR="/var/www/operastudio-ai-mobile"
STATIC_DIR="/var/www/operastudio-ai-static/mobile"
API_PORT="3002"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 Starting Local Build + Digital Ocean Deployment..."

# Step 1: Build Flutter web app locally (fast!)
print_status "🏗️ Building Flutter web app locally..."
flutter clean
flutter pub get
flutter build web \
    --release \
    --base-href="/mobile/" \
    --tree-shake-icons \
    --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/ \
    --dart-define=flutter.web.use_skia=false

print_success "✅ Local build completed in $(pwd)"

# Step 2: Copy built web files to server
print_status "📁 Deploying web files to Digital Ocean..."
scp -r build/web/* $SERVER_USER@$SERVER_IP:$STATIC_DIR/

# Step 3: Copy API server files
print_status "📦 Copying API server files..."
scp server.js package.json operastudio-api.service $SERVER_USER@$SERVER_IP:$DEPLOY_DIR/

# Step 4: Set up API server on Digital Ocean
print_status "⚙️ Setting up API server on Digital Ocean..."
ssh $SERVER_USER@$SERVER_IP << EOF
cd $DEPLOY_DIR

# Create .env file
echo "ENVIRONMENT=prod
DEBUG_MODE=false
LOG_LEVEL=info
API_BASE_URL=https://operastudio.io
WEB_API_ENDPOINT=https://operastudio.io/.netlify/functions
SUPABASE_URL=https://rnygtixdxbnflxflzpyr.supabase.co
SUPABASE_ANON_KEY=sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3
REPLICATE_API_TOKEN=r8_Xpygu1Vx0lqIGGJRkGMPvdQiLvJNEUqKwZQJ2
REPLICATE_MODEL_ID=mranderson01901234/my-app-scunetrepliactemodel
REPLICATE_MODEL_VERSION=df9a3c1d
PORT=$API_PORT
NODE_ENV=production" > .env

# Stop existing services and clean up
systemctl stop operastudio-api 2>/dev/null || true
pkill -f "node.*server.js" 2>/dev/null || true
sleep 2

# Clean up port
if lsof -i :$API_PORT > /dev/null 2>&1; then
    lsof -t -i :$API_PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Install dependencies and start service
npm install --production --no-optional
cp operastudio-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable operastudio-api
systemctl start operastudio-api
sleep 3

# Set proper permissions
chown -R www-data:www-data $STATIC_DIR
chmod -R 755 $STATIC_DIR
chown -R www-data:www-data $DEPLOY_DIR

# Configure Nginx
cat > /etc/nginx/sites-available/operastudio-api << 'NGINX_EOF'
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
NGINX_EOF

# Update Nginx config if needed
if ! grep -q "include /etc/nginx/sites-available/operastudio-api" /etc/nginx/sites-available/default; then
    sed -i '/^}$/i\    # Include API proxy configuration\n    include /etc/nginx/sites-available/operastudio-api;' /etc/nginx/sites-available/default
fi

# Test and reload Nginx
nginx -t && systemctl reload nginx

echo "🧪 Testing deployment..."
if systemctl is-active --quiet operastudio-api; then
    echo "✅ API server is running on port $API_PORT"
    curl -s http://localhost:$API_PORT/health
else
    echo "❌ API server failed to start"
    systemctl status operastudio-api --no-pager
    exit 1
fi
EOF

# Step 5: Final tests
print_status "🧪 Running final tests..."
sleep 3

# Test mobile app
if curl -s -I https://operastudio.io/mobile/ | grep -q "200 OK"; then
    print_success "✅ Mobile app is accessible"
else
    print_error "❌ Mobile app is not accessible"
fi

# Test API endpoints
PREDICT_TEST=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"test": "connectivity"}' https://operastudio.io/.netlify/functions/replicate-predict 2>/dev/null || echo "000")
HTTP_CODE="${PREDICT_TEST: -3}"

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
    print_success "✅ API endpoints are accessible (${HTTP_CODE} = working as expected)"
else
    print_error "❌ API endpoints returned: $HTTP_CODE"
fi

print_success "🎉 DEPLOYMENT COMPLETED!"
echo ""
echo "================================================"
echo "📱 Mobile App: https://operastudio.io/mobile/"
echo "🖥️  API Server: Running on port $API_PORT"
echo "🧪 Test image upload from iPhone and desktop!"
echo "================================================" 