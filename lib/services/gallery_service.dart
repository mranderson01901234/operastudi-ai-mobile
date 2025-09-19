import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import '../config/app_logger.dart';

enum SaveLocation {
  downloads,
  both  // For future gallery support
}

enum ExportFormat {
  png,
  jpeg
}

class GalleryService {
  /// Save image with multiple options
  static Future<Map<String, dynamic>> saveImage({
    required File imageFile,
    required SaveLocation location,
    ExportFormat format = ExportFormat.png,
    int jpegQuality = 90,
    String? customFileName,
  }) async {
    try {
      AppLogger.info('Starting image save process');
      
      // Check permissions first
      final hasPermissions = await _checkPermissions(location);
      if (!hasPermissions) {
        throw Exception('Storage permissions not granted');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'enhanced_image_$timestamp';
      final extension = format == ExportFormat.png ? 'png' : 'jpg';
      final fullFileName = '$fileName.$extension';

      Map<String, dynamic> result = {
        'success': false,
        'galleryPath': null,
        'downloadsPath': null,
        'fileName': fullFileName,
      };

      // Process image format if needed
      File processedFile = imageFile;
      if (format == ExportFormat.jpeg && imageFile.path.endsWith('.png')) {
        processedFile = await _convertToJpeg(imageFile, jpegQuality);
      }

      // Note: Gallery save currently disabled due to package compatibility issues
      // This will be implemented in a future update with a more stable package
      if (location == SaveLocation.both) {
        AppLogger.info('Gallery save requested but currently unavailable - saving to Downloads only');
      }

      // Save to Downloads folder (always happens for now)
      try {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final downloadsFile = File('${directory.path}/$fullFileName');
          await processedFile.copy(downloadsFile.path);
          result['downloadsPath'] = downloadsFile.path;
          AppLogger.info('Image saved to Downloads folder successfully: $fullFileName');
        } else {
          throw Exception('Downloads directory not available');
        }
      } catch (e) {
        AppLogger.error('Failed to save to Downloads', e);
        throw Exception('Failed to save to Downloads: ${e.toString()}');
      }

      // Clean up temporary JPEG file if created
      if (processedFile != imageFile) {
        try {
          await processedFile.delete();
        } catch (e) {
          AppLogger.info('Could not delete temporary file: $e');
        }
      }

      result['success'] = true;
      return result;

    } catch (e) {
      AppLogger.error('Gallery save failed', e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Share image with native share dialog or platform-specific fallback
  static Future<bool> shareImage({
    required File imageFile,
    String? text,
    String? subject,
  }) async {
    try {
      AppLogger.info('Sharing image via native share dialog');
      
      // Check if we're on Linux desktop where share_plus isn't supported
      if (Platform.isLinux && !kIsWeb) {
        return await _shareImageLinux(imageFile, text, subject);
      }
      
      final result = await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: text ?? 'Enhanced with Opera Studio AI',
        subject: subject ?? 'My Enhanced Image',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      AppLogger.error('Failed to share image', e);
      
      // Fallback for unsupported platforms
      if (Platform.isLinux && !kIsWeb) {
        return await _shareImageLinux(imageFile, text, subject);
      }
      
      return false;
    }
  }

  /// Linux-specific share implementation
  static Future<bool> _shareImageLinux(File imageFile, String? text, String? subject) async {
    try {
      AppLogger.info('Using Linux fallback share method');
      
      // Copy image to a temporary location with a user-friendly name
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sharedImagePath = '${tempDir.path}/enhanced_image_$timestamp.png';
      await imageFile.copy(sharedImagePath);
      
      // Try to open the file manager at the temp directory location
      try {
        final result = await Process.run('xdg-open', [tempDir.path]);
        if (result.exitCode == 0) {
          AppLogger.info('Opened file manager for manual sharing');
          return true;
        }
      } catch (e) {
        AppLogger.info('Could not open file manager: $e');
      }
      
      // Alternative: try to copy to clipboard using xclip if available
      try {
        final result = await Process.run('which', ['xclip']);
        if (result.exitCode == 0) {
          // Copy file path to clipboard using echo and pipe
          final clipboardResult = await Process.run('sh', ['-c', 'echo "$sharedImagePath" | xclip -selection clipboard']);
          if (clipboardResult.exitCode == 0) {
            AppLogger.info('Image path copied to clipboard for manual sharing');
            return true;
          }
        }
      } catch (e) {
        AppLogger.info('xclip not available: $e');
      }
      
      // Final fallback: just save to Downloads with notification
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final finalPath = '${downloadsDir.path}/shared_enhanced_image_$timestamp.png';
        await imageFile.copy(finalPath);
        AppLogger.info('Image saved to Downloads for manual sharing: $finalPath');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Linux share fallback failed', e);
      return false;
    }
  }

  /// Check required permissions for file operations
  static Future<bool> _checkPermissions(SaveLocation location) async {
    try {
      // Check storage permissions for Downloads
      final storageStatus = await Permission.storage.status;
      if (storageStatus != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result != PermissionStatus.granted) {
          AppLogger.info('Storage permission denied, but continuing anyway');
          // Don't fail completely - Downloads might still work on some devices
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Permission check failed', e);
      return true; // Continue anyway
    }
  }

  /// Convert PNG to JPEG with quality control
  static Future<File> _convertToJpeg(File pngFile, int quality) async {
    try {
      AppLogger.info('Converting PNG to JPEG with quality: $quality');
      
      final bytes = await pngFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Convert to JPEG with specified quality
      final jpegBytes = img.encodeJpg(image, quality: quality);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final jpegFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await jpegFile.writeAsBytes(jpegBytes);
      
      AppLogger.info('JPEG conversion completed: ${jpegBytes.length} bytes');
      return jpegFile;
      
    } catch (e) {
      AppLogger.error('JPEG conversion failed', e);
      return pngFile; // Fallback to original
    }
  }

  /// Check if gallery save is available on this platform
  static Future<bool> isGallerySaveAvailable() async {
    try {
      // Check if we have the necessary permissions
      final photoStatus = await Permission.photos.status;
      return photoStatus == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Request gallery permissions
  static Future<bool> requestGalleryPermissions() async {
    try {
      final result = await Permission.photos.request();
      return result == PermissionStatus.granted;
    } catch (e) {
      AppLogger.error('Failed to request gallery permissions', e);
      return false;
    }
  }
} 