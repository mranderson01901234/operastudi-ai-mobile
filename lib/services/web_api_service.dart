import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;


class WebAPIService {
  // Production API endpoints - FIXED: Use production URL
  static const String baseUrl = 'https://operastudio.io';
  static const String replicatePredictEndpoint = '/.netlify/functions/replicate-predict';
  static const String replicateStatusEndpoint = '/.netlify/functions/replicate-status';
  static const String enhanceGeneralEndpoint = '/.netlify/functions/api-v1-enhance-general';
  
  // Note: These endpoints may not exist yet, but keeping them for future implementation
  static const String userCreditsEndpoint = '/.netlify/functions/api-v1-user-credits';
  static const String userHistoryEndpoint = '/.netlify/functions/api-v1-user-history';
  static const String apiKeysEndpoint = '/.netlify/functions/api-v1-api-keys-list';
  
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Test API connectivity
  static Future<void> testAPIConnection() async {
    try {
      // Test with a minimal POST request to see if endpoint responds
      final response = await http.post(
        Uri.parse('$baseUrl$replicatePredictEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'test': 'connectivity'}),
      ).timeout(const Duration(seconds: 10));
      
      print('API Test - Status: ${response.statusCode}');
      print('API Test - Response: ${response.body}');
      
      if (response.statusCode == 400) {
        print('✅ Endpoint exists and responds (400 = bad request, expected without proper data)');
      } else if (response.statusCode == 401) {
        print('✅ Endpoint exists but requires authentication');
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Endpoint accessible');
      } else if (response.statusCode == 404) {
        print('❌ Endpoint not found - Check deployment');
      } else {
        print('⚠️ Endpoint returned: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network error: $e');
    }
  }

  // Test authentication
  static Future<void> testAuthentication() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        print('✅ User authenticated: ${session.user.email}');
        print('✅ Token expires: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}');
        
        // Test authenticated request
        final response = await http.post(
          Uri.parse('$baseUrl$replicatePredictEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: json.encode({'test': 'auth'}),
        ).timeout(const Duration(seconds: 10));
        
        print('✅ Authenticated request status: ${response.statusCode}');
      } else {
        print('❌ No authentication session');
      }
    } catch (e) {
      print('❌ Auth test error: $e');
    }
  }

  // Test basic API connectivity - PHASE 1 SUCCESS CRITERIA
  static Future<void> testApiConnection() async {
    try {
      final session = _supabase.auth.currentSession;
      String? token;
      
      if (session != null) {
        token = session.accessToken;
        print('🔐 Using authenticated token for API test');
      } else {
        print('⚠️ No authentication session - testing endpoint availability only');
      }

      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'OperaStudio-Mobile/1.0.0',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Test the status endpoint first (lighter weight)
      print('🧪 Testing status endpoint...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/.netlify/functions/replicate-status/test'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Status endpoint test: ${statusResponse.statusCode}');
      
      // Test the predict endpoint
      print('🧪 Testing predict endpoint...');
      final predictResponse = await http.post(
        Uri.parse('$baseUrl$replicatePredictEndpoint'),
        headers: headers,
        body: json.encode({'test': 'connectivity'}),
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Predict endpoint test: ${predictResponse.statusCode}');
      print('📡 Response: ${predictResponse.body}');
      
      // Evaluate results
      if (predictResponse.statusCode == 400) {
        print('✅ API Test PASSED: Endpoint exists and validates requests (400 = bad request expected for test data)');
      } else if (predictResponse.statusCode == 401) {
        print('✅ API Test PASSED: Endpoint exists but requires proper authentication');
      } else if (predictResponse.statusCode == 200 || predictResponse.statusCode == 201) {
        print('✅ API Test PASSED: Endpoint fully accessible');
      } else if (predictResponse.statusCode == 404) {
        print('❌ API Test FAILED: Endpoint not found - Check deployment');
      } else {
        print('⚠️ API Test PARTIAL: Endpoint returned ${predictResponse.statusCode}');
      }
      
    } catch (e) {
      print('❌ API Test FAILED: Network error: $e');
    }
  }

  // Get user credits (placeholder - endpoint may not exist yet)
  static Future<Map<String, dynamic>> getUserCredits() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$userCreditsEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get credits: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Get credits error: $e');
      // Return mock data for development
      return {
        'credits_remaining': 10,
        'subscription_tier': 'free',
      };
    }
  }

  // Get user history (placeholder - endpoint may not exist yet)
  static Future<Map<String, dynamic>> getUserHistory() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$userHistoryEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Get history error: $e');
      // Return mock data for development
      return {
        'history': [],
        'total_processed': 0,
      };
    }
  }

  // Enhance image using General Enhancement model - PRODUCTION MODE
  static Future<Map<String, dynamic>> enhanceGeneral(File imageFile) async {
    try {
      // CRITICAL FIX: Get fresh session with validation
      var session = _supabase.auth.currentSession;
      
      // Check if session is expired and refresh if needed
      if (session != null && session.expiresAt != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final now = DateTime.now();
        
        if (expiresAt.isBefore(now.add(const Duration(minutes: 5)))) {
          print('🔄 Session expires soon, refreshing...');
          try {
            final refreshResult = await _supabase.auth.refreshSession();
            if (refreshResult.session != null) {
              session = refreshResult.session!;
              print('✅ Session refreshed successfully');
            }
          } catch (e) {
            print('❌ Session refresh failed: $e');
            throw Exception('Session expired. Please sign in again.');
          }
        }
      }
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
        print('🔐 Using authenticated session: ${session.user?.email}');
        print('🔍 Token first 20 chars: ${session.accessToken.substring(0, 20)}...');
      } else {
        print('❌ No authentication session - API call will fail');
        throw Exception('User must be authenticated to use AI enhancement');
      }

      // Convert and compress image to prevent 413 errors
      final compressedDataUrl = await _prepareImageForAPI(imageFile);
      print('📊 Compressed image prepared for API');

      // Create request body matching your web platform format - FIXED PARAMETERS
      final requestBody = {
        'input': {
          'image': compressedDataUrl,
          'scale': 2,              // Correct: Integer (matches netlify function expectation)
          'sharpen': 45,           // Add missing parameters
          'denoise': 30,
          'face_recovery': false   // Correct: snake_case (matches replicate API expectation)
        }
      };

      // COMPREHENSIVE DEBUG LOGGING
      print('🔍 API DEBUG:');
      print('URL: $baseUrl$enhanceGeneralEndpoint');  // FIXED: Correct endpoint in logs
      print('Headers: $headers');
      print('Body: ${json.encode(requestBody)}');
      print('🚀 PRODUCTION: Starting API call to: $baseUrl$enhanceGeneralEndpoint');  // FIXED: Correct endpoint in logs
      print('📊 Request body size: ${json.encode(requestBody).length} bytes');

      // CRITICAL FIX: Use correct enhance-general endpoint instead of replicate-predict
      final response = await http.post(
        Uri.parse('$baseUrl$enhanceGeneralEndpoint'),  // FIXED: Use enhance-general endpoint
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Check if we got a proper Replicate response
        if (responseData.containsKey('id')) {
          print('✅ Got Replicate prediction ID: ${responseData['id']}');
          return responseData;
        } else {
          print('❌ Unexpected response format from API');
          throw Exception('Invalid response format from API: ${response.body}');
        }
      } else {
        print('❌ API Error ${response.statusCode}: ${response.body}');
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      print('❌ Enhancement failed: $e');
      // Test mode removed - no fallback service available
      throw Exception('Enhancement failed: ${e.toString()}');
    }
  }

  // Check status of enhancement
  static Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      print('🔍 Checking status for prediction: $predictionId');

      // CRITICAL FIX: Add authentication headers to status check
      var session = _supabase.auth.currentSession;
      
      // Check if session is expired and refresh if needed
      if (session != null && session.expiresAt != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final now = DateTime.now();
        
        if (expiresAt.isBefore(now.add(const Duration(minutes: 5)))) {
          print('🔄 Status check: Session expires soon, refreshing...');
          try {
            final refreshResult = await _supabase.auth.refreshSession();
            if (refreshResult.session != null) {
              session = refreshResult.session!;
              print('✅ Status check: Session refreshed successfully');
            }
          } catch (e) {
            print('❌ Status check: Session refresh failed: $e');
            throw Exception('Session expired. Please sign in again.');
          }
        }
      }
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
        print('🔐 Status check: Using authenticated session');
      } else {
        print('❌ Status check: No authentication session');
        throw Exception('User must be authenticated to check status');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$replicateStatusEndpoint/$predictionId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Status check result: ${result['status']}');
        return result;
      } else {
        throw Exception('Status check failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Status check error: $e');
      throw Exception('Status check failed: ${e.toString()}');
    }
  }

  // Download enhanced image
  static Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      print('📥 Downloading image from: $imageUrl');
      
      final response = await http.get(
        Uri.parse(imageUrl),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Image downloaded successfully: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  /// Prepare image for API by compressing and resizing to prevent 413 errors
  static Future<String> _prepareImageForAPI(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      print('📊 Original image size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
      
      // Decode the image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Unable to decode image file');
      }
      
      print('📊 Original dimensions: ${image.width}x${image.height}');
      
      // Calculate target dimensions (max 1024px on longest side)
      const maxDimension = 1024;
      int targetWidth = image.width;
      int targetHeight = image.height;
      
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          targetWidth = maxDimension;
          targetHeight = (maxDimension * image.height / image.width).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (maxDimension * image.width / image.height).round();
        }
        print('📊 Resizing to: ${targetWidth}x${targetHeight}');
      }
      
      // Resize if needed
      img.Image processedImage = image;
      if (targetWidth != image.width || targetHeight != image.height) {
        processedImage = img.copyResize(
          image, 
          width: targetWidth, 
          height: targetHeight,
          interpolation: img.Interpolation.linear
        );
      }
      
      // Compress with quality control
      List<int> compressedBytes;
      int quality = 85; // Start with good quality
      
      do {
        compressedBytes = img.encodeJpg(processedImage, quality: quality);
        final sizeKB = compressedBytes.length / 1024;
        print('📊 Compressed at quality $quality: ${sizeKB.toStringAsFixed(1)}KB');
        
        // Target: Keep under 500KB for base64 encoding (which increases size by ~33%)
        if (compressedBytes.length <= 500 * 1024 || quality <= 50) {
          break;
        }
        
        quality -= 10; // Reduce quality and try again
      } while (quality > 30);
      
      final finalSizeKB = compressedBytes.length / 1024;
      print('📊 Final compressed size: ${finalSizeKB.toStringAsFixed(1)}KB');
      
      // Convert to base64 data URL
      final base64Image = base64Encode(compressedBytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';
      
      // Check final payload size (base64 adds ~33% overhead)
      final payloadSizeKB = dataUrl.length / 1024;
      print('📊 Final payload size: ${payloadSizeKB.toStringAsFixed(1)}KB');
      
      if (payloadSizeKB > 1000) { // Warn if over 1MB
        print('⚠️ Large payload size: ${payloadSizeKB.toStringAsFixed(1)}KB - may cause timeouts');
      }
      
      return dataUrl;
      
    } catch (e) {
      print('❌ Image compression failed: $e');
      // Fallback to original image if compression fails
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    }
  }
}
