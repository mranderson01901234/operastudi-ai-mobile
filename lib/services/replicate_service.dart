import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'debug_service.dart';

class ReplicateService {
  static const String _baseUrl = 'https://api.replicate.com/v1';
  static const String _deploymentId = 'mranderson01901234/my-app-scunetrepliactemodel';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Cache for API token
  static String? _cachedApiToken;
  
  /// Get API token from secure storage or environment
  static Future<String?> _getApiToken() async {
    if (_cachedApiToken != null) return _cachedApiToken;
    
    try {
      // Try to get from secure storage first
      _cachedApiToken = await _storage.read(key: 'replicate_api_token');
      
      // If not found in storage, try environment variable
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
            if (output is String) {
              return output;
            } else if (output is List && output.isNotEmpty) {
              return output.first;
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
}
