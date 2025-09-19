import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_logger.dart';

class CloudStorageService {
  static const String bucketName = 'user-images';
  
  /// Upload image to Supabase Storage
  static Future<Map<String, dynamic>> uploadImage(
    File imageFile,
    String userId, {
    String? customFileName,
  }) async {
    try {
      AppLogger.info('Starting image upload to cloud storage');
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'enhanced_image_$timestamp.png';
      final storagePath = '$userId/$fileName';
      
      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      AppLogger.info('Image file size: ${bytes.length} bytes');
      
      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from(bucketName)
          .uploadBinary(storagePath, bytes);
      
      AppLogger.info('Image uploaded successfully');
      
      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(storagePath);
      
      AppLogger.info('Public URL generated: $publicUrl');
      
      return {
        'success': true,
        'storagePath': storagePath,
        'publicUrl': publicUrl,
        'fileName': fileName,
        'fileSize': bytes.length,
      };
      
    } catch (e) {
      AppLogger.error('Failed to upload image to cloud storage', e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Download image from Supabase Storage
  static Future<Uint8List?> downloadImage(String storagePath) async {
    try {
      AppLogger.info('Downloading image from cloud storage: $storagePath');
      
      final bytes = await Supabase.instance.client.storage
          .from(bucketName)
          .download(storagePath);
      
      AppLogger.info('Image downloaded successfully: ${bytes.length} bytes');
      return bytes;
      
    } catch (e) {
      AppLogger.error('Failed to download image from cloud storage', e);
      return null;
    }
  }
  
  /// Delete image from Supabase Storage
  static Future<bool> deleteImage(String storagePath) async {
    try {
      AppLogger.info('Deleting image from cloud storage: $storagePath');
      
      await Supabase.instance.client.storage
          .from(bucketName)
          .remove([storagePath]);
      
      AppLogger.info('Image deleted successfully');
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to delete image from cloud storage', e);
      return false;
    }
  }
  
  /// Get user's images from storage
  static Future<List<Map<String, dynamic>>> getUserImages(String userId) async {
    try {
      AppLogger.info('Fetching user images from cloud storage');
      
      final response = await Supabase.instance.client.storage
          .from(bucketName)
          .list();
      
      AppLogger.info('Found ${response.length} images for user');
      
      return response.map((file) {
        final fileObj = file as Map<String, dynamic>;
        return {
          'name': fileObj['name'],
          'path': '$userId/${fileObj['name']}',
          'size': fileObj['metadata']?['size'],
          'created_at': fileObj['created_at'],
        };
      }).toList();
      
    } catch (e) {
      AppLogger.error('Failed to fetch user images from cloud storage', e);
      return [];
    }
  }
  
  /// Save image metadata to database
  static Future<bool> saveImageMetadata({
    required String userId,
    required String originalFilename,
    required String storagePath,
    required int fileSize,
    String? mimeType,
    String processingType = 'general_enhancement',
    int creditsConsumed = 1,
  }) async {
    try {
      AppLogger.info('Saving image metadata to database');
      
      await Supabase.instance.client
          .from('user_images')
          .insert({
            'user_id': userId,
            'original_filename': originalFilename,
            'storage_path': storagePath,
            'file_size': fileSize,
            'mime_type': mimeType ?? 'image/png',
            'processing_type': processingType,
            'credits_consumed': creditsConsumed,
          });
      
      AppLogger.info('Image metadata saved successfully');
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to save image metadata to database', e);
      return false;
    }
  }
  
  /// Get user's image history from database
  static Future<List<Map<String, dynamic>>> getUserImageHistory(String userId) async {
    try {
      AppLogger.info('Fetching user image history from database');
      
      final response = await Supabase.instance.client
          .from('user_images')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      AppLogger.info('Found ${response.length} image records for user');
      
      // Fix: Properly cast the response to the expected type
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      AppLogger.error('Failed to fetch user image history from database', e);
      return [];
    }
  }
}
