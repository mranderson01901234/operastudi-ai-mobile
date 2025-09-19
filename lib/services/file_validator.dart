import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility class for file validation and type detection
/// Supports HEIC/HEIF files for iOS compatibility
class FileValidator {
  /// Supported image file extensions
  static const List<String> supportedExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff',
    'heic', 'heif' // Critical addition for iOS support
  ];
  
  /// Supported MIME types
  static const List<String> supportedMimeTypes = [
    'image/jpeg', 'image/png', 'image/webp', 'image/bmp', 'image/tiff',
    'image/heic', 'image/heif'
  ];
  
  /// Maximum file size for processing (20MB)
  static const int maxFileSizeBytes = 20 * 1024 * 1024;
  
  /// Validate if file is a supported image format
  static bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    return supportedExtensions.contains(extension);
  }
  
  /// Check if file is HEIC/HEIF format
  static bool isHEICFile(File file) {
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    return extension == 'heic' || extension == 'heif';
  }
  
  /// Get user-friendly file type display name
  static String getFileTypeDisplay(File file) {
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    switch (extension) {
      case 'heic':
        return 'iPhone HEIC Image';
      case 'heif':
        return 'iPhone HEIF Image';
      case 'jpg':
      case 'jpeg':
        return 'JPEG Image';
      case 'png':
        return 'PNG Image';
      case 'webp':
        return 'WebP Image';
      case 'bmp':
        return 'BMP Image';
      case 'tiff':
        return 'TIFF Image';
      default:
        return '${extension.toUpperCase()} Image';
    }
  }
  
  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Check if file size is within acceptable limits
  static bool isFileSizeAcceptable(File file) {
    try {
      final fileSize = file.lengthSync();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      return false;
    }
  }
  
  /// Get comprehensive file validation result
  static FileValidationResult validateFile(File file) {
    if (!file.existsSync()) {
      return const FileValidationResult(
        isValid: false,
        errorMessage: 'File does not exist',
        fileType: 'Unknown',
        fileSize: 0,
      );
    }
    
    if (!isValidImageFile(file)) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Unsupported file format. Please select a JPEG, PNG, or HEIC image.',
        fileType: getFileTypeDisplay(file),
        fileSize: file.lengthSync(),
      );
    }
    
    if (!isFileSizeAcceptable(file)) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'File too large. Please select an image smaller than 20MB.',
        fileType: getFileTypeDisplay(file),
        fileSize: file.lengthSync(),
      );
    }
    
    return FileValidationResult(
      isValid: true,
      errorMessage: null,
      fileType: getFileTypeDisplay(file),
      fileSize: file.lengthSync(),
      isHEIC: isHEICFile(file),
    );
  }
  
  /// Log file information for debugging
  static void logFileInfo(File file) {
    final result = validateFile(file);
    if (kDebugMode) print('📁 File validation result:');
    if (kDebugMode) print('   Type: ${result.fileType}');
    if (kDebugMode) print('   Size: ${formatFileSize(result.fileSize)}');
    if (kDebugMode) print('   Valid: ${result.isValid}');
    if (kDebugMode) print('   HEIC: ${result.isHEIC}');
    if (!result.isValid) {
      if (kDebugMode) print('   Error: ${result.errorMessage}');
    }
  }
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String fileType;
  final int fileSize;
  final bool isHEIC;
  
  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.fileType,
    required this.fileSize,
    this.isHEIC = false,
  });
}
