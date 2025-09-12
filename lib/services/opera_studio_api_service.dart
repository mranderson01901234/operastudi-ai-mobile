import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/opera_studio_config.dart';
import '../exceptions/custom_exceptions.dart';

class OperaStudioAPIService {
  static final http.Client _client = http.Client();

  static Future<Map<String, dynamic>> enhanceGeneral(File imageFile) async {
    try {
      // Get session with retry
      final session = await _getSessionWithRetry();
      
      // Prepare image with validation
      final base64Image = await _prepareImageForUpload(imageFile);
      
      final requestBody = {
        'input': {
          'image': base64Image,
          ...OperaStudioConfig.defaultEnhancementSettings,
        }
      };

      final response = await _client.post(
        Uri.parse('${OperaStudioConfig.apiBaseUrl}${OperaStudioConfig.predictEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

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
      ).timeout(Duration(seconds: 10));

      return _handleApiResponse(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Uint8List> downloadImage(String url) async {
    try {
      final response = await _client.get(Uri.parse(url))
          .timeout(Duration(seconds: 30));
      
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
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    if (expiresAt.isBefore(DateTime.now().add(Duration(minutes: 5)))) {
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
    
    // Validate image
    if (bytes.length > OperaStudioConfig.maxFileSizeBytes) {
      throw Exception('Image too large');
    }
    
    final base64Image = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64Image';
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
