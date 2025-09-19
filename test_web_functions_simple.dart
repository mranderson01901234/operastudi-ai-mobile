#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class SimpleWebFunctionTester {
  static Future<void> main() async {
    print('🚀 Starting Simple Web Function Tests');
    print('=' * 60);
    
    // Test API endpoints directly
    await _testApiEndpoints();
    await _testImageProcessing();
    await _testAuthentication();
    
    print('\n✅ All tests completed!');
  }
  
  static Future<void> _testApiEndpoints() async {
    print('\n🌐 TESTING API ENDPOINTS');
    print('-' * 40);
    
    final endpoints = [
      'http://localhost:8888/.netlify/functions/replicate-predict',
      'http://localhost:8888/.netlify/functions/replicate-status',
      'http://localhost:8888/.netlify/functions/user-credits',
      'http://localhost:8888/.netlify/functions/user-history',
      'http://localhost:8888/.netlify/functions/api-keys',
    ];
    
    for (final endpoint in endpoints) {
      try {
        print('Testing endpoint: $endpoint');
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(endpoint));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Test-Mode', 'true');
        
        final response = await request.close();
        print('✅ Endpoint response: ${response.statusCode}');
        
        if (response.statusCode != 200) {
          print('⚠️ Non-200 response: ${response.statusCode}');
        }
        
        client.close();
      } catch (e) {
        print('❌ Endpoint test failed: $e');
      }
    }
  }
  
  static Future<void> _testImageProcessing() async {
    print('\n🖼️ TESTING IMAGE PROCESSING');
    print('-' * 40);
    
    try {
      // Test image enhancement API
      print('Testing image enhancement API...');
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('http://localhost:8888/.netlify/functions/replicate-predict'));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Test-Mode', 'true');
      
      // Create test request body
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
      
      print('✅ Image processing API response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        print('✅ API response body: $responseBody');
      } else {
        final errorBody = await response.transform(utf8.decoder).join();
        print('❌ API error: $errorBody');
      }
      
      client.close();
    } catch (e) {
      print('❌ Image processing test failed: $e');
    }
  }
  
  static Future<void> _testAuthentication() async {
    print('\n🔐 TESTING AUTHENTICATION');
    print('-' * 40);
    
    try {
      // Test Supabase connection
      print('Testing Supabase connection...');
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://your-supabase-url.supabase.co/rest/v1/'));
      request.headers.set('apikey', 'your-anon-key');
      request.headers.set('Authorization', 'Bearer your-anon-key');
      
      final response = await request.close();
      print('✅ Supabase connection response: ${response.statusCode}');
      
      client.close();
    } catch (e) {
      print('❌ Authentication test failed: $e');
    }
  }
}

// Run the tests
void main() async {
  await SimpleWebFunctionTester.main();
}
