#!/bin/bash

# ============================================
# Mobile App Deployment Script for Digital Ocean
# ============================================

set -e  # Exit on any error

echo "🚀 Starting Mobile App Deployment..."

# Configuration
REPO_URL="https://github.com/mranderson01901234/operastudi-ai-mobile.git"
DEPLOY_DIR="/var/www/operastudio-ai-mobile"
STATIC_DIR="/var/www/operastudio-ai-static/mobile"
BRANCH="main"

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

if [ "$AVAILABLE_MEM" -lt 1024 ]; then
    print_warning "Low memory detected (${AVAILABLE_MEM}MB available). Creating temporary swap..."
    # Create 2GB swap file if it doesn't exist
    if [ ! -f /swapfile_flutter ]; then
        fallocate -l 2G /swapfile_flutter
        chmod 600 /swapfile_flutter
        mkswap /swapfile_flutter
        swapon /swapfile_flutter
        print_status "✅ Temporary 2GB swap created"
    else
        swapon /swapfile_flutter 2>/dev/null || true
        print_status "✅ Existing swap activated"
    fi
fi

print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    print_status "Installation guide: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

# Step 3: Create production .env file for web build
print_status "Creating production environment configuration..."
cat > .env << 'EOF'
ENVIRONMENT=prod
DEBUG_MODE=false
LOG_LEVEL=info
API_BASE_URL=https://operastudio.io
WEB_API_ENDPOINT=https://operastudio.io/.netlify/functions
SUPABASE_URL=
SUPABASE_ANON_KEY=
REPLICATE_API_TOKEN=
EOF
print_status "✅ Production .env created"

# Step 4: Install dependencies
print_status "Installing Flutter dependencies..."
if [[ $EUID -eq 0 ]]; then
    # Run as a regular user to avoid Flutter root warnings
    sudo -u $SUDO_USER flutter pub get
else
    flutter pub get
fi

# Step 5: Build web app with memory optimizations
print_status "Building Flutter web app with memory optimizations..."
if [[ $EUID -eq 0 ]]; then
    # Run as a regular user to avoid Flutter root warnings
    sudo -u $SUDO_USER flutter build web --release --base-href="/mobile/" --tree-shake-icons --no-source-maps --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/
else
    flutter build web --release --base-href="/mobile/" --tree-shake-icons --no-source-maps --dart-define=flutter.web.canvaskit.url=https://unpkg.com/canvaskit-wasm@latest/bin/
fi

# Step 6: Create mobile directory if it doesn't exist
print_status "Setting up mobile directory..."
mkdir -p "$STATIC_DIR"

# Step 7: Copy built files to static directory
print_status "Deploying files to static directory..."
cp -r build/web/* "$STATIC_DIR/"

# Step 8: Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data "$STATIC_DIR"
chmod -R 755 "$STATIC_DIR"

# Step 9: Verify deployment
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

# Step 10: Test web server configuration
print_status "Testing Nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    print_success "✅ Nginx configuration is valid"
    print_status "Reloading Nginx..."
    systemctl reload nginx
    print_success "✅ Nginx reloaded successfully"
else
    print_warning "⚠️  Nginx configuration test failed - please check manually"
fi

# Cleanup temporary swap if we created it
if [ -f /swapfile_flutter ]; then
    print_status "Cleaning up temporary swap..."
    swapoff /swapfile_flutter 2>/dev/null || true
    # Don't remove the file, keep it for future builds
    print_status "✅ Swap deactivated (keeping file for future builds)"
fi

print_success "🎉 Mobile app deployment completed!"
print_status "Next steps:"
print_status "1. Update Nginx configuration for mobile detection (if not done yet)"
print_status "2. Test the mobile app at https://operastudio.io/mobile/"
print_status "3. Configure mobile user-agent detection"

echo ""
echo "================================================"
echo "🚀 Deployment Summary:"
echo "📁 Source: $REPO_URL"
echo "📂 Deploy Dir: $DEPLOY_DIR" 
echo "🌐 Static Dir: $STATIC_DIR"
echo "🔗 URL: https://operastudio.io/mobile/"
echo "================================================" 