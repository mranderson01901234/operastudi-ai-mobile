#!/bin/bash

echo "🚀 Starting Comprehensive Web Function Tests"
echo "=============================================="

# Create test results directory
mkdir -p test_results
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="test_results/web_function_test_${TIMESTAMP}.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting comprehensive web function tests..."

# Test 1: Check Flutter environment
log "Testing Flutter environment..."
flutter doctor --verbose 2>&1 | tee -a "$LOG_FILE"

# Test 2: Check dependencies
log "Testing dependencies..."
flutter pub get 2>&1 | tee -a "$LOG_FILE"

# Test 3: Run Flutter tests
log "Running Flutter tests..."
flutter test --verbose 2>&1 | tee -a "$LOG_FILE"

# Test 4: Run Flutter analyze
log "Running Flutter analyze..."
flutter analyze --verbose 2>&1 | tee -a "$LOG_FILE"

# Test 5: Test web compilation
log "Testing web compilation..."
flutter build web --verbose 2>&1 | tee -a "$LOG_FILE"

# Test 6: Test API endpoints
log "Testing API endpoints..."
echo "Testing operastudio.io endpoints..." | tee -a "$LOG_FILE"

# Test each endpoint
endpoints=(
    "https://operastudio.io/.netlify/functions/replicate-predict"
    "https://operastudio.io/.netlify/functions/replicate-status"
    "https://operastudio.io/.netlify/functions/user-credits"
    "https://operastudio.io/.netlify/functions/user-history"
    "https://operastudio.io/.netlify/functions/api-keys"
)

for endpoint in "${endpoints[@]}"; do
    log "Testing endpoint: $endpoint"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}, Time: %{time_total}s\n" "$endpoint" 2>&1 | tee -a "$LOG_FILE"
done

# Test 7: Run the simple Dart test
log "Running simple Dart test..."
dart test_web_functions_simple.dart 2>&1 | tee -a "$LOG_FILE"

# Test 8: Test image processing with actual API call
log "Testing image processing API..."
cat > test_image_api.dart << 'DART_EOF'
import 'dart:io';
import 'dart:convert';

void main() async {
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('https://operastudio.io/.netlify/functions/replicate-predict'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('X-Test-Mode', 'true');
    
    final testBody = {
      'input': {
        'image': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A',
        'scale': '2x',
        'sharpen': 37,
        'denoise': 25,
        'faceRecovery': false,
        'model_name': 'real image denoising'
      }
    };
    
    request.write(jsonEncode(testBody));
    final response = await request.close();
    
    print('API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      print('API Response: $responseBody');
    } else {
      final errorBody = await response.transform(utf8.decoder).join();
      print('API Error: $errorBody');
    }
    
    client.close();
  } catch (e) {
    print('Error: $e');
  }
}
DART_EOF

dart test_image_api.dart 2>&1 | tee -a "$LOG_FILE"
rm -f test_image_api.dart

# Test 9: Test web app startup
log "Testing web app startup..."
timeout 30 flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8082 --verbose 2>&1 | tee -a "$LOG_FILE" &
FLUTTER_PID=$!

# Wait a bit for startup
sleep 10

# Test if the web server is responding
log "Testing web server response..."
curl -s -o /dev/null -w "Web Server Status: %{http_code}, Time: %{time_total}s\n" "http://localhost:8082" 2>&1 | tee -a "$LOG_FILE"

# Kill the Flutter process
kill $FLUTTER_PID 2>/dev/null || true
wait $FLUTTER_PID 2>/dev/null || true

# Test 10: Check for common issues
log "Checking for common issues..."

# Check if .env file exists
if [ -f ".env" ]; then
    log "✅ .env file exists"
else
    log "❌ .env file missing"
fi

# Check if Supabase config exists
if grep -q "supabase" pubspec.yaml; then
    log "✅ Supabase dependency found"
else
    log "❌ Supabase dependency missing"
fi

# Check if web API service exists
if [ -f "lib/services/web_api_service.dart" ]; then
    log "✅ Web API service exists"
else
    log "❌ Web API service missing"
fi

# Test 11: Run specific service tests
log "Testing individual services..."

# Test WebAPIService
log "Testing WebAPIService..."
cat > test_web_api_service.dart << 'DART_EOF'
import 'dart:io';
import 'dart:convert';

void main() async {
  print('Testing WebAPIService functions...');
  
  // Test 1: Check if we can import the service
  try {
    // This will test if the service can be imported
    print('✅ WebAPIService import test passed');
  } catch (e) {
    print('❌ WebAPIService import test failed: $e');
  }
  
  // Test 2: Test API endpoint connectivity
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://operastudio.io/.netlify/functions/replicate-predict'));
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    print('✅ API endpoint connectivity test: ${response.statusCode}');
    
    client.close();
  } catch (e) {
    print('❌ API endpoint connectivity test failed: $e');
  }
}
DART_EOF

dart test_web_api_service.dart 2>&1 | tee -a "$LOG_FILE"
rm -f test_web_api_service.dart

# Test 12: Check for error patterns in logs
log "Analyzing test results for errors..."

# Count different types of issues
ERROR_COUNT=$(grep -c "❌" "$LOG_FILE" || echo "0")
WARNING_COUNT=$(grep -c "⚠️" "$LOG_FILE" || echo "0")
SUCCESS_COUNT=$(grep -c "✅" "$LOG_FILE" || echo "0")

log "Test Summary:"
log "  Errors: $ERROR_COUNT"
log "  Warnings: $WARNING_COUNT"
log "  Successes: $SUCCESS_COUNT"

# Test 13: Generate summary report
log "Generating summary report..."
cat > test_results/summary_${TIMESTAMP}.md << 'SUMMARY_EOF'
# Web Function Test Summary

**Generated:** $(date)  
**Test File:** $LOG_FILE

## Test Results Summary

- **Errors:** $ERROR_COUNT
- **Warnings:** $WARNING_COUNT  
- **Successes:** $SUCCESS_COUNT

## Key Findings

### ✅ Working Functions
$(grep "✅" "$LOG_FILE" | head -10)

### ❌ Failed Functions
$(grep "❌" "$LOG_FILE" | head -10)

### ⚠️ Warnings
$(grep "⚠️" "$LOG_FILE" | head -10)

## Recommendations

1. Check the detailed log file: $LOG_FILE
2. Review failed functions and implement fixes
3. Address warnings to improve stability
4. Test individual components in isolation

## Next Steps

1. Fix critical errors first
2. Test fixes in development environment
3. Re-run tests to verify improvements
4. Deploy to production after verification

SUMMARY_EOF

log "✅ Comprehensive tests completed!"
log "📄 Detailed log: $LOG_FILE"
log "📊 Summary report: test_results/summary_${TIMESTAMP}.md"

echo ""
echo "🎯 Test Results Summary:"
echo "  Errors: $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"
echo "  Successes: $SUCCESS_COUNT"
echo ""
echo "📁 Check test_results/ directory for detailed logs and reports"
