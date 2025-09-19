import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'debug_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReplicateService {
  static const String _baseUrl = 'https://api.replicate.com/v1';
  // Deployment ID for the 'General' model (formerly 'ScuNet')
  static const String _deploymentId = 'mranderson01901234/my-app-scunetrepliactemodel';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Cache for API token
  static String? _cachedApiToken;
  
  /// Get API token from secure storage or environment
  static Future<String?> _getApiToken() async {
    if (_cachedApiToken != null) return _cachedApiToken;

    // 1. Try to get from .env first
    final envToken = dotenv.env['REPLICATE_API_TOKEN'];
    if (envToken != null && envToken.isNotEmpty) {
      _cachedApiToken = envToken;
      if (kDebugMode) {
        DebugService.log(
          '🔐 ReplicateService: API token loaded from .env',
          level: DebugLevel.info,
          tag: 'ReplicateService',
        );
      }
      return _cachedApiToken;
    }

    try {
      // 2. Try to get from secure storage
      _cachedApiToken = await _storage.read(key: 'replicate_api_token');
      // 3. If not found in storage, try environment variable
      if (_cachedApiToken == null || _cachedApiToken!.isEmpty) {
        _cachedApiToken = const String.fromEnvironment('REPLICATE_API_TOKEN');
      }
      
      // Validate token format
      if (_cachedApiToken != null && _cachedApiToken!.isNotEmpty) {
        if (kDebugMode) {
          DebugService.log(
            '🔐 ReplicateService: API token loaded successfully',
            level: DebugLevel.info,
            tag: 'ReplicateService',
          );
        }
        return _cachedApiToken;
      } else {
        throw Exception('REPLICATE_API_TOKEN not found in environment or secure storage');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: Failed to get API token: $e',
          level: DebugLevel.error,
          tag: 'ReplicateService',
        );
      }
      rethrow;
    }
  }
  
  /// Set API token in secure storage
  static Future<void> setApiToken(String token) async {
    try {
      await _storage.write(key: 'replicate_api_token', value: token);
      _cachedApiToken = token;
      
      if (kDebugMode) {
        DebugService.log(
          '🔐 ReplicateService: API token saved to secure storage',
          level: DebugLevel.info,
          tag: 'ReplicateService',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: Failed to save API token: $e',
          level: DebugLevel.error,
          tag: 'ReplicateService',
        );
      }
      rethrow;
    }
  }
  
  /// Validate API token by making a test request
  static Future<bool> validateApiToken() async {
    try {
      final token = await _getApiToken();
      if (token == null) return false;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      
      final isValid = response.statusCode == 200;
      
      if (kDebugMode) {
        DebugService.log(
          '🔐 ReplicateService: Token validation ${isValid ? "successful" : "failed"}',
          level: isValid ? DebugLevel.info : DebugLevel.error,
          tag: 'ReplicateService',
          data: {'statusCode': response.statusCode},
        );
      }
      
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: Token validation error: $e',
          level: DebugLevel.error,
          tag: 'ReplicateService',
        );
      }
      return false;
    }
  }
  
  /// Enhance image using Replicate API
  static Future<String?> enhanceImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        DebugService.log(
          '🚀 ReplicateService: Starting AI enhancement',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {
            'imagePath': imageFile.path,
            'fileSize': await imageFile.length(),
          },
        );
      }
      
      // Step 1: Upload image to Replicate
      final imageUrl = await _uploadImage(imageFile);
      if (imageUrl == null) {
        throw Exception('Failed to upload image to Replicate');
      }
      
      if (kDebugMode) {
        DebugService.log(
          '📤 ReplicateService: Image uploaded successfully',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {'imageUrl': imageUrl},
        );
      }
      
      // Step 2: Create prediction
      final predictionId = await _createPrediction(imageUrl);
      if (predictionId == null) {
        throw Exception('Failed to create prediction');
      }
      
      if (kDebugMode) {
        DebugService.log(
          '🎯 ReplicateService: Prediction created',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {'predictionId': predictionId},
        );
      }
      
      // Step 3: Wait for completion and get result
      final resultUrl = await _waitForCompletion(predictionId);
      
      stopwatch.stop();
      
      if (kDebugMode) {
        DebugService.log(
          '✅ ReplicateService: AI enhancement completed',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {
            'duration': stopwatch.elapsedMilliseconds,
            'resultUrl': resultUrl,
          },
        );
      }
      
      return resultUrl;
      
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: AI enhancement failed',
          level: DebugLevel.error,
          tag: 'ReplicateService',
          data: {
            'duration': stopwatch.elapsedMilliseconds,
            'error': e.toString(),
          },
        );
      }
      
      throw Exception('AI enhancement failed: $e');
    }
  }
  
  /// Upload image to Replicate
  static Future<String?> _uploadImage(File imageFile) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/files'),
      );
      
      request.headers['Authorization'] = 'Token $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data['urls']['get'];
      } else {
        final errorData = json.decode(responseBody);
        throw Exception('Upload failed: ${response.statusCode} - ${errorData['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }
  
  /// Create prediction with Replicate
  static Future<String?> _createPrediction(String imageUrl) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/predictions'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'version': _deploymentId,
          'input': {
            'image': imageUrl,
          },
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Prediction creation failed: ${response.statusCode} - ${errorData['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Prediction creation error: $e');
    }
  }
  
  /// Wait for prediction completion
  static Future<String?> _waitForCompletion(String predictionId) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      
      int attempts = 0;
      const maxAttempts = 60; // 2 minutes max wait time
      
      while (attempts < maxAttempts) {
        final response = await http.get(
          Uri.parse('$_baseUrl/predictions/$predictionId'),
          headers: {
            'Authorization': 'Token $token',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final status = data['status'];
          
          if (kDebugMode && attempts % 5 == 0) {
            DebugService.log(
              '⏳ ReplicateService: Prediction status: $status (attempt $attempts)',
              level: DebugLevel.debug,
              tag: 'ReplicateService',
            );
          }
          
          if (status == 'succeeded') {
            final output = data['output'];
            final resultUrl = _extractImageUrlFromOutput(output);
            if (resultUrl != null) {
              return resultUrl;
            }
            throw Exception('Unexpected output format: $output');
          } else if (status == 'failed') {
            final error = data['error'] ?? 'Unknown error';
            throw Exception('Prediction failed: $error');
          } else if (status == 'canceled') {
            throw Exception('Prediction was canceled');
          }
          
          // Wait 2 seconds before checking again
          await Future.delayed(const Duration(seconds: 2));
          attempts++;
        } else {
          throw Exception('Status check failed: ${response.statusCode}');
        }
      }
      
      throw Exception('Prediction timed out after ${maxAttempts * 2} seconds');
    } catch (e) {
      throw Exception('Completion wait error: $e');
    }
  }
  
  /// Download enhanced image from URL
  static Future<Uint8List?> downloadImage(String imageUrl) async {
    try {
      if (kDebugMode) {
        DebugService.log(
          '📥 ReplicateService: Downloading enhanced image',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {'imageUrl': imageUrl},
        );
      }
      
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          DebugService.log(
            '✅ ReplicateService: Image downloaded successfully',
            level: DebugLevel.info,
            tag: 'ReplicateService',
            data: {'size': response.bodyBytes.length},
          );
        }
        return response.bodyBytes;
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: Image download failed: $e',
          level: DebugLevel.error,
          tag: 'ReplicateService',
        );
      }
      throw Exception('Image download error: $e');
    }
  }
  
  /// Clear cached API token
  static Future<void> clearApiToken() async {
    try {
      await _storage.delete(key: 'replicate_api_token');
      _cachedApiToken = null;
      
      if (kDebugMode) {
        DebugService.log(
          '🧹 ReplicateService: API token cleared',
          level: DebugLevel.info,
          tag: 'ReplicateService',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ ReplicateService: Failed to clear API token: $e',
          level: DebugLevel.error,
          tag: 'ReplicateService',
        );
      }
    }
  }

  // Helper to get deployment ID and version by model name
  static Map<String, Map<String, String>> modelConfigs = {
    'General': {
      'deploymentId': 'mranderson01901234/my-app-scunetrepliactemodel',
      'version': 'df9a3c1d',
    },
    'Portrait': {
      'deploymentId': dotenv.env['PORTRAIT_MODEL_DEPLOYMENT_ID'] ?? 'portrait-pro-v1',
      'version': dotenv.env['PORTRAIT_MODEL_VERSION'] ?? 'v1.0',
    },
  };

  /// Create enhancement prediction for a given model
  static Future<String?> createEnhancementPrediction({
    required String imageUrl,
    required String modelName,
  }) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      final modelConfig = modelConfigs[modelName] ?? modelConfigs['General']!;
      final deploymentId = modelConfig['deploymentId'];
      final version = modelConfig['version'];
      final response = await http.post(
        Uri.parse('$_baseUrl/predictions'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'version': version,
          'deploymentId': deploymentId,
          'input': {
            'image': imageUrl,
          },
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Prediction creation failed: 	${response.statusCode} - ${errorData['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Prediction creation error: $e');
    }
  }

  /// Enhance image using the Replicate Portrait model (topazlabs/image-upscale)
  static Future<String?> enhancePortraitWithReplicate({
    required String imageUrl,
    String enhanceModel = 'Low Resolution V2',
    String upscaleFactor = '4x',
    bool faceEnhancement = true,
    String subjectDetection = 'Foreground',
    double faceEnhancementCreativity = 0.5,
  }) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      
      // FIXED: Use proper Replicate API format for topazlabs/image-upscale
      final modelName = dotenv.env['PORTRAIT_MODEL_NAME'] ?? 'topazlabs/image-upscale';
      
      // FIXED: Convert local file path to base64 data URL (like general model does)
      String imageData;
      if (imageUrl.startsWith('http')) {
        // Already a URL, use as is
        imageData = imageUrl;
      } else {
        // Local file path, convert to base64
        final file = File(imageUrl);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        imageData = 'data:image/jpeg;base64,$base64Image';
      }
      
      if (kDebugMode) {
        DebugService.log(
          '🟢 enhancePortraitWithReplicate',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {
            'model': modelName,
            'imageUrl': imageUrl,
            'imageDataType': imageData.startsWith('http') ? 'URL' : 'Base64',
            'enhanceModel': enhanceModel,
            'upscaleFactor': upscaleFactor,
            'faceEnhancement': faceEnhancement,
          },
        );
      }
      
      // FIXED: Use correct Replicate API format - version field with model name for public models
      final response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          // FIXED: Use 'version' with model name for public models like topazlabs/image-upscale
          'version': modelName,
          'input': {
            'image': imageData, // FIXED: Use processed image data (URL or base64)
            'enhance_model': enhanceModel,
            'upscale_factor': upscaleFactor,
            'face_enhancement': faceEnhancement,
            'subject_detection': subjectDetection,
            'face_enhancement_creativity': faceEnhancementCreativity,
          },
        }),
      );
      if (kDebugMode) {
        DebugService.log(
          '🟢 enhancePortraitWithReplicate response',
          level: DebugLevel.info,
          tag: 'ReplicateService',
          data: {
            'statusCode': response.statusCode,
            'body': response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body,
          },
        );
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // FIXED: Return prediction ID for status polling (like general model does)
        // Don't try to extract result URL immediately since output is null when starting
        if (data.containsKey('id')) {
          return data['id'];  // Return prediction ID for status polling
        }
        
        throw Exception('No prediction ID in response: ${response.body}');
      } else {
        throw Exception('Replicate API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ enhancePortraitWithReplicate error',
          level: DebugLevel.error,
          tag: 'ReplicateService',
          data: {'error': e.toString()},
        );
      }
      throw Exception('Portrait enhancement error: $e');
    }
  }

  /// Check status of a Replicate prediction
  static Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      final token = await _getApiToken();
      if (token == null) throw Exception('API token not available');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/predictions/$predictionId'),
        headers: {
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Status check failed: ${response.statusCode} - ${errorData['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Status check error: $e');
    }
  }

  // Defensive output extraction utility
  static String? _extractImageUrlFromOutput(dynamic output) {
    if (output == null) return null;
    if (output is String) return output;
    if (output is List && output.isNotEmpty) return output.first;
    if (output is Map && output.containsKey('denoised_image')) return output['denoised_image'];
    if (output is Map && output.containsKey('image')) return output['image'];
    return null;
  }
}
