#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

// Import the services we need to test
import 'lib/services/web_api_service.dart';
// Removed test service - test mode no longer supported
import 'lib/services/auth_service.dart';
import 'lib/services/app_state.dart';
import 'lib/services/camera_service.dart';
import 'lib/services/credit_service.dart';
import 'lib/services/processing_history_service.dart';
import 'lib/services/error_handler.dart';

class ComprehensiveWebFunctionTester {
  static const String testLogFile = 'web_function_test_results.log';
  static File? _logFile;
  
  static Future<void> main() async {
    print('🚀 Starting Comprehensive Web Function Tests');
    print('=' * 60);
    
    // Initialize log file
    await _initializeLogFile();
    
    // Run all test categories
    await _testAuthenticationFunctions();
    await _testImageProcessingFunctions();
    await _testCameraFunctions();
    await _testCreditFunctions();
    await _testAppStateFunctions();
    await _testErrorHandlingFunctions();
    await _testApiEndpoints();
    
    print('\n✅ All tests completed! Check $testLogFile for detailed results.');
  }
  
  static Future<void> _initializeLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/$testLogFile');
    await _logFile!.writeAsString('Comprehensive Web Function Test Results\n');
    await _logFile!.writeAsString('Generated: ${DateTime.now()}\n');
    await _logFile!.writeAsString('=' * 60 + '\n\n');
  }
  
  static Future<void> _log(String message) async {
    print(message);
    if (_logFile != null) {
      await _logFile!.writeAsString('$message\n', mode: FileMode.append);
    }
  }
  
  static Future<void> _testAuthenticationFunctions() async {
    await _log('\n🔐 TESTING AUTHENTICATION FUNCTIONS');
    await _log('-' * 40);
    
    try {
      // Test 1: Sign up with email
      await _log('Testing: AuthService.signUpWithEmail()');
      final signUpResult = await AuthService.signUpWithEmail(
        'test@example.com', 
        'testpassword123'
      );
      await _log('✅ Sign up result: ${signUpResult['success']}');
      if (!signUpResult['success']) {
        await _log('❌ Sign up error: ${signUpResult['error']}');
      }
    } catch (e) {
      await _log('❌ Sign up exception: $e');
    }
    
    try {
      // Test 2: Sign in with email
      await _log('Testing: AuthService.signInWithEmail()');
      final signInResult = await AuthService.signInWithEmail(
        'test@example.com', 
        'testpassword123'
      );
      await _log('✅ Sign in result: $signInResult');
    } catch (e) {
      await _log('❌ Sign in exception: $e');
    }
    
    try {
      // Test 3: Get current user
      await _log('Testing: AuthService.getCurrentUser()');
      final currentUser = AuthService.getCurrentUser();
      await _log('✅ Current user: ${currentUser?.email ?? 'null'}');
    } catch (e) {
      await _log('❌ Get current user exception: $e');
    }
    
    try {
      // Test 4: Check if signed in
      await _log('Testing: AuthService.isSignedIn');
      final isSignedIn = AuthService.isSignedIn;
      await _log('✅ Is signed in: $isSignedIn');
    } catch (e) {
      await _log('❌ Is signed in exception: $e');
    }
    
    try {
      // Test 5: Get user profile
      await _log('Testing: AuthService.getUserProfile()');
      final userProfile = await AuthService.getUserProfile();
      await _log('✅ User profile: ${userProfile != null ? 'Found' : 'Not found'}');
      if (userProfile != null) {
        await _log('   Credits: ${userProfile['credits_remaining']}');
      }
    } catch (e) {
      await _log('❌ Get user profile exception: $e');
    }
  }
  
  static Future<void> _testImageProcessingFunctions() async {
    await _log('\n🖼️ TESTING IMAGE PROCESSING FUNCTIONS');
    await _log('-' * 40);
    
    // Create a test image file
    final testImage = await _createTestImage();
    
    try {
      // Test 1: Web API Service - enhanceGeneral
      await _log('Testing: WebAPIService.enhanceGeneral()');
      final enhanceResult = await WebAPIService.enhanceGeneral(testImage);
      await _log('✅ Enhancement result: ${enhanceResult.containsKey('id') ? 'Success' : 'Failed'}');
      if (enhanceResult.containsKey('id')) {
        await _log('   Prediction ID: ${enhanceResult['id']}');
      }
    } catch (e) {
      await _log('❌ Enhancement exception: $e');
    }
    
    try {
      // Test 2: Web API Service Test - enhanceGeneral
              await _log('Testing: WebAPIService.enhanceGeneral() (test mode removed)');
    // Test mode service removed - only production authentication supported now
    await _log('⚠️ Skipping test mode - requires authentication');
    await _log('ℹ️ Test mode functionality has been removed - authentication required');
    } catch (e) {
      await _log('❌ Test enhancement exception: $e');
    }
    
    try {
      // Test 3: Check status
      await _log('Testing: WebAPIService.checkStatus()');
      final statusResult = await WebAPIService.checkStatus('test-prediction-id');
      await _log('✅ Status check result: ${statusResult.containsKey('status') ? 'Success' : 'Failed'}');
    } catch (e) {
      await _log('❌ Status check exception: $e');
    }
    
    try {
      // Test 4: Download image
      await _log('Testing: WebAPIService.downloadImage()');
      final imageBytes = await WebAPIService.downloadImage('https://via.placeholder.com/300x200');
      await _log('✅ Image download result: ${imageBytes.length} bytes');
    } catch (e) {
      await _log('❌ Image download exception: $e');
    }
  }
  
  static Future<void> _testCameraFunctions() async {
    await _log('\n📸 TESTING CAMERA FUNCTIONS');
    await _log('-' * 40);
    
    try {
      // Test 1: Check if emulator
      await _log('Testing: CameraService.getAvailableCameras()');
      final cameras = await CameraService.getAvailableCameras();
      await _log('✅ Available cameras: ${cameras.length}');
    } catch (e) {
      await _log('❌ Emulator check exception: $e');
    }
    
    try {
      // Test 2: Get available cameras
      await _log('Testing: CameraService.getAvailableCameras()');
      final cameras = await CameraService.getAvailableCameras();
      await _log('✅ Available cameras: ${cameras.length}');
      for (var camera in cameras) {
        await _log('   Camera: ${camera.name} (${camera.lensDirection})');
      }
    } catch (e) {
      await _log('❌ Get cameras exception: $e');
    }
    
    try {
      // Test 3: Get camera info
      await _log('Testing: CameraService.getCameraInfo()');
      final cameraInfo = await CameraService.getCameraInfo();
      await _log('✅ Camera info: ${cameraInfo.toString()}');
    } catch (e) {
      await _log('❌ Camera info exception: $e');
    }
    
    try {
      // Test 4: Pick from gallery
      await _log('Testing: CameraService.pickFromGallery()');
      final galleryImage = await CameraService.pickFromGallery();
      await _log('✅ Gallery pick result: ${galleryImage != null ? 'Success' : 'Cancelled'}');
    } catch (e) {
      await _log('❌ Gallery pick exception: $e');
    }
  }
  
  static Future<void> _testCreditFunctions() async {
    await _log('\n💰 TESTING CREDIT FUNCTIONS');
    await _log('-' * 40);
    
    try {
      // Test 1: Get user credits
      await _log('Testing: CreditService.getUserCredits()');
      final creditInfo = await CreditService.getUserCredits();
      await _log('✅ User credits: ${creditInfo['credits_remaining']}');
    } catch (e) {
      await _log('❌ Get credits exception: $e');
    }
    
    try {
      // Test 2: Deduct credits
      await _log('Testing: CreditService.deductCredits()');
      final creditService = CreditService(); final deductResult = await creditService.deductCredits(1);
      await _log('✅ Deduct credits result: $deductResult');
    } catch (e) {
      await _log('❌ Deduct credits exception: $e');
    }
  }
  
  static Future<void> _testAppStateFunctions() async {
    await _log('\n📱 TESTING APP STATE FUNCTIONS');
    await _log('-' * 40);
    
    final appState = AppState();
    
    try {
      // Test 1: Set selected image
      await _log('Testing: AppState.setSelectedImage()');
      final testImage = await _createTestImage();
      appState.setSelectedImage(testImage);
      await _log('✅ Set image result: ${appState.isImageLoaded}');
    } catch (e) {
      await _log('❌ Set image exception: $e');
    }
    
    try {
      // Test 2: Image editing properties
      await _log('Testing: AppState image editing properties');
      appState.setBrightness(0.5);
      appState.setContrast(0.3);
      appState.setSaturation(0.2);
      appState.setWarmth(0.1);
      appState.setSelectedFilter('vintage');
      await _log('✅ Image editing properties set');
      await _log('   Has adjustments: ${appState.hasAnyAdjustments}');
    } catch (e) {
      await _log('❌ Image editing exception: $e');
    }
    
    try {
      // Test 3: Add test credits
      await _log('Testing: AppState.addTestCredits()');
      appState.addTestCredits(5);
      await _log('✅ Test credits added: ${appState.userCredits}');
    } catch (e) {
      await _log('❌ Add credits exception: $e');
    }
    
    try {
      // Test 4: AI enhancement workflow
      await _log('Testing: AppState.enhanceImageWithAi()');
      await appState.enhanceImageWithAi('General'); // Add required modelName parameter
      await _log('✅ AI enhancement workflow completed');
    } catch (e) {
      await _log('❌ AI enhancement exception: $e');
    }
  }
  
  static Future<void> _testErrorHandlingFunctions() async {
    await _log('\n⚠️ TESTING ERROR HANDLING FUNCTIONS');
    await _log('-' * 40);
    
    try {
      // Test 1: Network error handling
      await _log('Testing: ErrorHandler.handleNetworkError()');
      final networkError = ErrorHandler.handleNetworkError('Connection timeout');
      await _log('✅ Network error handled: $networkError');
    } catch (e) {
      await _log('❌ Network error handling exception: $e');
    }
    
    try {
      // Test 2: Camera error handling
      await _log('Testing: ErrorHandler.handleCameraError()');
      final cameraError = await ErrorHandler.handleCameraError('No cameras available');
      await _log('✅ Camera error handled: $cameraError');
    } catch (e) {
      await _log('❌ Camera error handling exception: $e');
    }
  }
  
  static Future<void> _testApiEndpoints() async {
    await _log('\n🌐 TESTING API ENDPOINTS');
    await _log('-' * 40);
    
    final testImage = await _createTestImage();
    
    // Test all API endpoints
    final endpoints = [
      'https://operastudio.io/.netlify/functions/replicate-predict',
      'https://operastudio.io/.netlify/functions/replicate-status',
      'https://operastudio.io/.netlify/functions/user-credits',
      'https://operastudio.io/.netlify/functions/user-history',
      'https://operastudio.io/.netlify/functions/api-keys',
    ];
    
    for (final endpoint in endpoints) {
      try {
        await _log('Testing endpoint: $endpoint');
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(endpoint));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Test-Mode', 'true');
        
        final response = await request.close();
        await _log('✅ Endpoint response: ${response.statusCode}');
        
        if (response.statusCode != 200) {
          await _log('⚠️ Non-200 response: ${response.statusCode}');
        }
        
        client.close();
      } catch (e) {
        await _log('❌ Endpoint test failed: $e');
      }
    }
  }
  
  static Future<File> _createTestImage() async {
    final directory = await getTemporaryDirectory();
    final testImageFile = File('${directory.path}/test_image.jpg');
    
    // Create a minimal JPEG file for testing
    final jpegBytes = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x10,
      0x00, 0x20, 0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01,
      0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02,
      0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00,
      0xB5, 0x10, 0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03, 0x05, 0x05,
      0x04, 0x04, 0x00, 0x00, 0x01, 0x7D, 0x01, 0x02, 0x03, 0x00, 0x04, 0x11,
      0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07, 0x22, 0x71,
      0x14, 0x32, 0x81, 0x91, 0xA1, 0x08, 0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52,
      0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0A, 0x16, 0x17, 0x18,
      0x19, 0x1A, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x34, 0x35, 0x36, 0x37,
      0x38, 0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x53,
      0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x63, 0x64, 0x65, 0x66, 0x67,
      0x68, 0x69, 0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x83,
      0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x92, 0x93, 0x94, 0x95, 0x96,
      0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9,
      0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3,
      0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6,
      0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8,
      0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA,
      0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00,
      0x3F, 0x00, 0xFF, 0xD9
    ]);
    
    await testImageFile.writeAsBytes(jpegBytes);
    return testImageFile;
  }
}

// Run the tests
void main() async {
  await ComprehensiveWebFunctionTester.main();
}
