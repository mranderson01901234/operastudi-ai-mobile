#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class APIIntegrationTester {
  static const String baseUrl = 'http://localhost:8888';
  
  static Future<void> main() async {
    print('🧪 Testing API Integration');
    print('=' * 50);
    
    // Test 1: Check if Netlify functions are accessible
    await testNetlifyFunctions();
    
    // Test 2: Test replicate-predict endpoint
    await testReplicatePredict();
    
    // Test 3: Test replicate-status endpoint
    await testReplicateStatus();
    
    // Test 4: Test api-v1-enhance-general endpoint
    await testEnhanceGeneral();
    
    print('\n✅ API Integration tests completed!');
  }
  
  static Future<void> testNetlifyFunctions() async {
    print('\n🔍 Testing Netlify Functions Accessibility');
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
          print('  ❌ Endpoint not found');
        } else {
          print('  ⚠️ Unexpected status: ${response.statusCode}');
        }
      } catch (e) {
        print('  ❌ Error: $e');
      }
    }
  }
  
  static Future<void> testReplicatePredict() async {
    print('\n🚀 Testing Replicate Predict Endpoint');
    print('-' * 40);
    
    try {
      // Create a minimal test request
      final testRequest = {
        'input': {
          'image': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A',
          'scale': 2,
          'sharpen': 37,
          'denoise': 25,
          'face_recovery': false
        }
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/.netlify/functions/replicate-predict'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-token',
        },
        body: json.encode(testRequest),
      ).timeout(Duration(seconds: 10));
      
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 401) {
        print('✅ Endpoint working (authentication required)');
      } else if (response.statusCode == 201) {
        print('✅ Endpoint working (prediction created)');
      } else {
        print('⚠️ Unexpected response');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  static Future<void> testReplicateStatus() async {
    print('\n🔍 Testing Replicate Status Endpoint');
    print('-' * 40);
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/.netlify/functions/replicate-status/test-prediction-id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-token',
        },
      ).timeout(Duration(seconds: 10));
      
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 401) {
        print('✅ Endpoint working (authentication required)');
      } else if (response.statusCode == 200) {
        print('✅ Endpoint working (status retrieved)');
      } else {
        print('⚠️ Unexpected response');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  static Future<void> testEnhanceGeneral() async {
    print('\n🎨 Testing Enhance General Endpoint');
    print('-' * 40);
    
    try {
      // Create a test image file
      final testImageBytes = base64Decode('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A');
      
      // Create multipart form data
      final boundary = '----formdata-boundary-${DateTime.now().millisecondsSinceEpoch}';
      final body = StringBuffer();
      
      // Add image field
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="image"; filename="test.jpg"\r\n');
      body.write('Content-Type: image/jpeg\r\n\r\n');
      body.write(String.fromCharCodes(testImageBytes));
      body.write('\r\n');
      
      // Add settings
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="scale"\r\n\r\n');
      body.write('2x\r\n');
      
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="sharpen"\r\n\r\n');
      body.write('37\r\n');
      
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="denoise"\r\n\r\n');
      body.write('25\r\n');
      
      body.write('--$boundary--\r\n');
      
      final response = await http.post(
        Uri.parse('$baseUrl/.netlify/functions/api-v1-enhance-general'),
        headers: {
          'Content-Type': 'multipart/form-data; boundary=$boundary',
          'Authorization': 'Bearer test-token',
        },
        body: body.toString(),
      ).timeout(Duration(seconds: 10));
      
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 401) {
        print('✅ Endpoint working (authentication required)');
      } else if (response.statusCode == 200) {
        print('✅ Endpoint working (enhancement completed)');
      } else {
        print('⚠️ Unexpected response');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}

// Run the tests
void main() async {
  await APIIntegrationTester.main();
}
