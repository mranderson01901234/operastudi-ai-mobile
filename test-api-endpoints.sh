#!/bin/bash

# ============================================
# API Endpoints Test Script
# ============================================

echo "🧪 Testing Opera Studio API Endpoints..."

# Configuration
BASE_URL="https://operastudio.io"
LOCAL_URL="http://localhost:3001"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test 1: Health check (local)
print_status "Testing local API server health check..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:3001/health)
HTTP_CODE="${HEALTH_RESPONSE: -3}"
RESPONSE_BODY="${HEALTH_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "Local health check passed (200)"
    echo "Response: $RESPONSE_BODY"
else
    print_error "Local health check failed ($HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 2: Nginx proxy health check
print_status "Testing Nginx proxy to API server..."
PROXY_RESPONSE=$(curl -s -w "%{http_code}" https://operastudio.io/health 2>/dev/null || echo "000")
HTTP_CODE="${PROXY_RESPONSE: -3}"
RESPONSE_BODY="${PROXY_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "Nginx proxy health check passed (200)"
    echo "Response: $RESPONSE_BODY"
else
    print_error "Nginx proxy health check failed ($HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 3: Replicate predict endpoint (without auth - should return 401)
print_status "Testing replicate-predict endpoint (should return 401 without auth)..."
PREDICT_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"test": "connectivity"}' \
    https://operastudio.io/.netlify/functions/replicate-predict 2>/dev/null || echo "000")
HTTP_CODE="${PREDICT_RESPONSE: -3}"
RESPONSE_BODY="${PREDICT_RESPONSE%???}"

if [ "$HTTP_CODE" = "401" ]; then
    print_success "Replicate predict endpoint accessible (401 - auth required, as expected)"
    echo "Response: $RESPONSE_BODY"
elif [ "$HTTP_CODE" = "404" ]; then
    print_error "Replicate predict endpoint not found (404)"
    echo "Response: $RESPONSE_BODY"
else
    print_error "Replicate predict endpoint unexpected response ($HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 4: General enhancement endpoint (without auth - should return 401)
print_status "Testing api-v1-enhance-general endpoint (should return 401 without auth)..."
ENHANCE_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"test": "connectivity"}' \
    https://operastudio.io/.netlify/functions/api-v1-enhance-general 2>/dev/null || echo "000")
HTTP_CODE="${ENHANCE_RESPONSE: -3}"
RESPONSE_BODY="${ENHANCE_RESPONSE%???}"

if [ "$HTTP_CODE" = "401" ]; then
    print_success "General enhancement endpoint accessible (401 - auth required, as expected)"
    echo "Response: $RESPONSE_BODY"
elif [ "$HTTP_CODE" = "404" ]; then
    print_error "General enhancement endpoint not found (404)"
    echo "Response: $RESPONSE_BODY"
else
    print_error "General enhancement endpoint unexpected response ($HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 5: CORS preflight request
print_status "Testing CORS preflight request..."
CORS_RESPONSE=$(curl -s -w "%{http_code}" -X OPTIONS \
    -H "Origin: https://operastudio.io" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type,Authorization" \
    https://operastudio.io/.netlify/functions/replicate-predict 2>/dev/null || echo "000")
HTTP_CODE="${CORS_RESPONSE: -3}"

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    print_success "CORS preflight request passed ($HTTP_CODE)"
else
    print_error "CORS preflight request failed ($HTTP_CODE)"
fi

echo ""

# Test 6: Check systemd service status
print_status "Checking API server service status..."
if systemctl is-active --quiet operastudio-api; then
    print_success "API server service is running"
    SERVICE_STATUS=$(systemctl show operastudio-api --property=ActiveState,SubState --no-pager)
    echo "Status: $SERVICE_STATUS"
else
    print_error "API server service is not running"
    echo "Recent logs:"
    journalctl -u operastudio-api --lines=5 --no-pager
fi

echo ""

# Summary
echo "================================================"
echo "🧪 API Test Summary Complete"
echo "================================================"
echo ""
echo "If tests show 401 errors, this is GOOD - it means the endpoints"
echo "are accessible but require authentication (as expected)."
echo ""
echo "If tests show 404 errors, the API server or Nginx configuration"
echo "may need to be fixed."
echo ""
echo "To monitor API server logs in real-time:"
echo "  journalctl -u operastudio-api -f"
echo ""
echo "To restart the API server:"
echo "  sudo systemctl restart operastudio-api" 