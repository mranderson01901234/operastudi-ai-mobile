import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class WebAPIServiceTest {
  // ✅ FIXED: Use web app's actual API endpoints
  static const String baseUrl = 'http://10.0.2.2:8888';
  static const String enhanceGeneralEndpoint = '/.netlify/functions/replicate-predict';
  static const String userCreditsEndpoint = '/.netlify/functions/user-credits';
  static const String userHistoryEndpoint = '/.netlify/functions/user-history';
  static const String apiKeysEndpoint = '/.netlify/functions/api-keys';
  
  // Test API key for development
  static const String testApiKey = 'test-api-key-here';

  // Enhance image using General Enhancement model (TEST VERSION - WEB APP API)
  static Future<Map<String, dynamic>> enhanceGeneral(File imageFile) async {
    try {
      print('🧪 TEST MODE: Using web app API endpoint');

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      // ✅ CORRECT: Send JSON to replicate-predict
      final requestBody = {
        'input': {
          'image': dataUrl,
          'scale': '2x',
          'sharpen': 37,
          'denoise': 25,
          'faceRecovery': false,
          'model_name': 'real image denoising'
        }
      };

      print('🧪 TEST: Starting API call to: $baseUrl$enhanceGeneralEndpoint');
      print('🧪 TEST: Request body size: ${bytes.length} bytes');

      final response = await http.post(
        Uri.parse('$baseUrl$enhanceGeneralEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-Test-Mode': 'true',
          'X-Test-User': 'flutter-test-user',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('🧪 TEST: API Response Status: ${response.statusCode}');
      print('🧪 TEST: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // ✅ FALLBACK: Return mock response if web app unavailable
        print('🧪 TEST: Web app unavailable, using mock response');
        return _getMockResponse();
      }
    } catch (e) {
      print('🧪 TEST: API Error: $e');
      // ✅ FALLBACK: Return mock response on error
      return _getMockResponse();
    }
  }

  // ✅ FALLBACK: Mock response when web app unavailable
  static Map<String, dynamic> _getMockResponse() {
    return {
      'success': true,
      'data': {
        'jobId': 'mock-job-${DateTime.now().millisecondsSinceEpoch}',
        'processingTime': 2.5,
        'creditsUsed': 1,
        'resultUrl': 'https://via.placeholder.com/800x600/4CAF50/FFFFFF?text=Mock+Enhanced',
        'thumbnailUrl': 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=Mock+Thumb',
        'metadata': {
          'originalSize': '2.3MB',
          'enhancedSize': '8.4MB',
          'dimensions': '1920x1080',
          'quality': 9.2,
          'testMode': true,
        }
      }
    };
  }

  // Check status of enhancement (TEST VERSION - WEB APP API)
  static Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      print('🧪 TEST: Checking status for prediction: $predictionId');

      final response = await http.get(
        Uri.parse('$baseUrl/.netlify/functions/replicate-status/$predictionId'),
        headers: {
          'X-Test-Mode': 'true',
          'X-Test-User': 'flutter-test-user',
        },
      ).timeout(Duration(seconds: 10));

      print('🧪 TEST: Status Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return mock status
        return {
          'id': predictionId,
          'status': 'succeeded',
          'created_at': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
          'output': [
            'https://via.placeholder.com/800x600/4CAF50/FFFFFF?text=Mock+Enhanced'
          ],
          'error': null
        };
      }
    } catch (e) {
      print('🧪 TEST: Status check error: $e');
      // Return mock status
      return {
        'id': predictionId,
        'status': 'succeeded',
        'created_at': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'output': [
          'https://via.placeholder.com/800x600/4CAF50/FFFFFF?text=Mock+Enhanced'
        ],
        'error': null
      };
    }
  }

  // Download enhanced image (TEST VERSION)
  static Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      print('🧪 TEST: Downloading image from: $imageUrl');

      // If it's a placeholder URL, return mock image data
      if (imageUrl.contains('placeholder.com')) {
        print('🧪 TEST: Using mock image data for placeholder URL');
        return _getMockImageData();
      }

      final response = await http.get(Uri.parse(imageUrl)).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        print('🧪 TEST: Image downloaded successfully: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        throw Exception('Image download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🧪 TEST: Image download error: $e');
      // Return mock image data as fallback
      return _getMockImageData();
    }
  }

  // ✅ MOCK: Generate mock image data
  static Uint8List _getMockImageData() {
    // Create a minimal JPEG header
    return Uint8List.fromList([
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
  }

  // Poll for result with progress callback (TEST VERSION)
  static Future<Map<String, dynamic>> pollForResult(
    String predictionId,
    Function(double progress, String status) onProgress,
  ) async {
    const maxAttempts = 6; // Reduced for testing (30 seconds with 5-second intervals)
    const interval = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final statusData = await checkStatus(predictionId);
        final status = statusData['status'] ?? 'unknown';
        final progress = (attempt / maxAttempts) * 100;
        
        print('🧪 TEST: Poll attempt $attempt/$maxAttempts - Status: $status');
        onProgress(progress, 'Status: $status');
        
        if (status == 'succeeded') {
          return statusData;
        } else if (status == 'failed') {
          throw Exception('Enhancement failed: ${statusData['error'] ?? 'Unknown error'}');
        }
        
        if (attempt < maxAttempts) {
          await Future.delayed(interval);
        }
      } catch (e) {
        print('🧪 TEST: Poll error on attempt $attempt: $e');
        if (attempt == maxAttempts) {
          throw Exception('Polling timeout: $e');
        }
        await Future.delayed(interval);
      }
    }
    
    throw Exception('Enhancement timeout after $maxAttempts attempts');
  }
}
