import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WebAPIService {
  // Your web platform API endpoints
  static const String baseUrl = 'https://operastudio.io/.netlify/functions';
  static const String predictEndpoint = '/replicate-predict';
  static const String statusEndpoint = '/replicate-status';
  
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Enhance image using General Enhancement model
  static Future<Map<String, dynamic>> enhanceGeneral(File imageFile) async {
    try {
      // Get authenticated session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }

      // Convert image to base64 (required format for your API)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      // Create request body matching your web platform format
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

      print('Starting API call to: $baseUrl$predictEndpoint');
      print('JWT Token (first 20 chars): ${session.accessToken.substring(0, 20)}...');

      // Make API call with JWT authentication
      final response = await http.post(
        Uri.parse('$baseUrl$predictEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      print('API Error: $e');
      throw Exception('Enhancement failed: ${e.toString()}');
    }
  }

  // Check processing status
  static Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }

      print('Checking status for prediction: $predictionId');

      final response = await http.get(
        Uri.parse('$baseUrl$statusEndpoint/$predictionId'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(Duration(seconds: 10));

      print('Status Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Status check failed ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      print('Status check error: $e');
      throw Exception('Status check failed: ${e.toString()}');
    }
  }

  // Poll for completion with progress tracking
  static Future<Map<String, dynamic>> pollForResult(
    String predictionId, {
    Function(double progress, String status)? onProgress,
  }) async {
    print('Starting polling for prediction: $predictionId');
    
    for (int attempt = 0; attempt < 120; attempt++) { // 2 minutes max
      try {
        final result = await checkStatus(predictionId);
        final status = result['status'];
        
        print('Poll attempt $attempt: Status = $status');

        if (status == 'succeeded') {
          onProgress?.call(1.0, 'Complete!');
          return result;
        } else if (status == 'failed') {
          throw Exception('Processing failed: ${result['error'] ?? 'Unknown error'}');
        }

        // Update progress
        double progress = 0.3 + (attempt / 120.0) * 0.7; // 30% to 100%
        onProgress?.call(progress, 'Processing...');

        // Wait 1 second before next check
        await Future.delayed(Duration(seconds: 1));

      } catch (e) {
        print('Poll attempt $attempt failed: $e');
        if (attempt == 119) rethrow; // Last attempt, rethrow error
      }
    }

    throw Exception('Processing timeout after 2 minutes');
  }

  // Download enhanced image
  static Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      print('Downloading image from: $imageUrl');
      
      final response = await http.get(Uri.parse(imageUrl))
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('Image downloaded successfully: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
      throw Exception('Failed to download enhanced image: $e');
    }
  }
}
