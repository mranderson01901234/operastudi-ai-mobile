import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../config/opera_studio_config.dart';
import '../exceptions/custom_exceptions.dart';

class OperaStudioAPIService {
  static final http.Client _client = http.Client();

  static Future<Map<String, dynamic>> enhanceGeneral(File imageFile) async {
    return await enhanceImageWithRetry(imageFile, OperaStudioConfig.defaultEnhancementSettings);
  }

  static Future<Map<String, dynamic>> enhancePortrait(File imageFile) async {
    // Copy default settings and override model_name for Portrait
    final portraitSettings = Map<String, dynamic>.from(OperaStudioConfig.defaultEnhancementSettings)
      ..['model_name'] = 'portrait-pro-v1';
    return await enhanceImageWithRetry(imageFile, portraitSettings);
  }

  static Future<Map<String, dynamic>> enhanceImageWithRetry(File imageFile, Map<String, dynamic> settings) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        return await _performEnhancement(imageFile, settings);
      } catch (error) {
        if (error.toString().contains('rate limited') && attempt < 3) {
          await Future.delayed(Duration(seconds: 30 * attempt));
          continue;
        }
        if (attempt == 3) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    throw Exception('All retries failed');
  }

  static Future<Map<String, dynamic>> _performEnhancement(File imageFile, Map<String, dynamic> settings) async {
    try {
      // Get session with retry
      final session = await _getSessionWithRetry();
      
      // Prepare image with validation and downsizing
      final base64Image = await _prepareImageForUpload(imageFile);
      
      final requestBody = {
        'input': {
          'image': base64Image,
          ...settings,
        }
      };

      final response = await _client.post(
        Uri.parse('${OperaStudioConfig.apiBaseUrl}${OperaStudioConfig.predictEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      return _handleApiResponse(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      final session = await _getSessionWithRetry();
      
      final response = await _client.get(
        Uri.parse('${OperaStudioConfig.apiBaseUrl}${OperaStudioConfig.statusEndpoint}/$predictionId'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      return _handleApiResponse(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Uint8List> downloadImage(String url) async {
    try {
      final response = await _client.get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw ProcessingException('Failed to download enhanced image');
    }
  }

  static Future<Session> _getSessionWithRetry() async {
    Session? session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      throw Exception('User not authenticated');
    }
    
    // Check if token is about to expire (within 5 minutes)
    if (session.expiresAt == null) {
      throw Exception('Session expiration time is null');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    if (expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      // Refresh token
      final refreshedSession = await Supabase.instance.client.auth.refreshSession();
      if (refreshedSession.session == null) {
        throw Exception('Failed to refresh session');
      }
      session = refreshedSession.session!;
    }
    
    return session;
  }

  static Future<String> _prepareImageForUpload(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    print('📊 Original image size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
    
    // Check if image needs downsizing
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image file');
    
    print('📊 Original dimensions: ${image.width}x${image.height}');
    
    // Use more conservative max dimension to prevent 413 errors
    const maxDimension = 2048; // Reduced from 8192
    img.Image processedImage = image;
    
    if (image.width > maxDimension || image.height > maxDimension) {
      // Calculate new size maintaining aspect ratio
      int newWidth, newHeight;
      if (image.width > image.height) {
        newWidth = maxDimension;
        newHeight = (maxDimension * image.height / image.width).round();
      } else {
        newHeight = maxDimension;
        newWidth = (maxDimension * image.width / image.height).round();
      }
      
      print('📊 Resizing to: ${newWidth}x${newHeight}');
      processedImage = img.copyResize(image, width: newWidth, height: newHeight);
    }
    
    // Use progressive compression to stay under size limits
    List<int> compressedBytes;
    int quality = 85;
    
    do {
      compressedBytes = img.encodeJpg(processedImage, quality: quality);
      final sizeKB = compressedBytes.length / 1024;
      print('📊 Compressed at quality $quality: ${sizeKB.toStringAsFixed(1)}KB');
      
      // Target: Keep under 800KB for base64 encoding
      if (compressedBytes.length <= 800 * 1024 || quality <= 50) {
        break;
      }
      
      quality -= 10;
    } while (quality > 30);
    
    final finalSizeKB = compressedBytes.length / 1024;
    print('📊 Final compressed size: ${finalSizeKB.toStringAsFixed(1)}KB');
    
    return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
  }

  static Map<String, dynamic> _handleApiResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed');
    } else if (response.statusCode == 402) {
      throw InsufficientCreditsException('Insufficient credits');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limited');
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  static Exception _mapException(dynamic error) {
    if (error is TimeoutException) {
      return TimeoutException('Request timed out');
    } else if (error is SocketException) {
      return Exception('Network error. Please check your connection.');
    } else {
      return Exception('Processing failed: ${error.toString()}');
    }
  }
}
