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
   print_status "Running as root - proceeding with deployment"
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

# Step 2: Check Flutter installation
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    print_status "Installation guide: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

# Step 3: Install dependencies
print_status "Installing Flutter dependencies..."
flutter pub get

# Step 4: Build web app
print_status "Building Flutter web app..."
flutter build web --release --web-renderer canvaskit --base-href="/mobile/"

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

# Step 8: Verify deployment
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

# Step 9: Test web server configuration
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