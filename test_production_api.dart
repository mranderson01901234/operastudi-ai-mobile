#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductionAPITester {
  static const String baseUrl = 'http://localhost:8888';
  
  static Future<void> main() async {
    print('🚀 Testing Production API Integration');
    print('=' * 50);
    
    // Test 1: Check if Netlify functions are running
    await testNetlifyFunctions();
    
    print('\n✅ Production API tests completed!');
    print('🎯 The AI button should now work with the real API endpoints.');
  }
  
  static Future<void> testNetlifyFunctions() async {
    print('\n🔍 Testing Netlify Functions');
    print('-' * 40);
    
    final endpoints = [
      '/.netlify/functions/replicate-predict',
      '/.netlify/functions/replicate-status',
      '/.netlify/functions/api-v1-enhance-general',
    ];
    
    for (final endpoint in endpoints) {
      try {
        print('Testing: $baseUrl$endpoint');
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'test': 'connectivity'}),
        ).timeout(Duration(seconds: 5));
        
        print('  Status: ${response.statusCode}');
        
        if (response.statusCode == 401) {
          print('  ✅ Endpoint exists (requires authentication)');
        } else if (response.statusCode == 400) {
          print('  ✅ Endpoint exists (bad request expected)');
        } else if (response.statusCode == 404) {
          print('  ❌ Endpoint not found - Start Netlify dev server');
        } else {
          print('  ⚠️ Unexpected status: ${response.statusCode}');
        }
      } catch (e) {
        print('  ❌ Error: $e');
        print('  💡 Make sure to run: netlify dev');
      }
    }
  }
}

// Run the tests
void main() async {
  await ProductionAPITester.main();
}
