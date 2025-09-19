import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

class ErrorHandler {
  static const String _tag = 'ErrorHandler';
  
  /// Handle camera-related errors with emulator-specific fallbacks
  static Future<String> handleCameraError(dynamic error, {String? context}) async {
    String userMessage = '';
    String errorType = '';
    
    if (kDebugMode) {
      DebugService.log(
        '📸 Camera error occurred: $error',
        level: DebugLevel.error,
        tag: _tag,
        data: {'context': context, 'error': error.toString()},
      );
    }
    
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          errorType = 'PERMISSION_DENIED';
          userMessage = 'Camera permission denied. Please enable camera access in device settings.';
          break;
        case 'camera_access_denied_without_prompt':
          errorType = 'PERMISSION_DENIED_PERMANENTLY';
          userMessage = 'Camera access permanently denied. Please enable it in device settings and restart the app.';
          break;
        case 'camera_access_restricted':
          errorType = 'PERMISSION_RESTRICTED';
          userMessage = 'Camera access is restricted on this device.';
          break;
        case 'no_available_camera':
          errorType = 'NO_CAMERA';
          userMessage = await _handleNoCameraError();
          break;
        default:
          errorType = 'PLATFORM_ERROR';
          userMessage = await _handleGenericCameraError(error);
          break;
      }
    } else if (error.toString().contains('No cameras available')) {
      errorType = 'NO_CAMERA';
      userMessage = await _handleNoCameraError();
    } else if (error.toString().contains('Failed to take photo')) {
      errorType = 'CAPTURE_FAILED';
      userMessage = await _handleCaptureFailedError();
    } else {
      errorType = 'UNKNOWN_CAMERA_ERROR';
      userMessage = 'Camera error occurred. You can still select images from gallery.';
    }
    
    if (kDebugMode) {
      DebugService.log(
        '🔧 Camera error handled: $errorType',
        level: DebugLevel.info,
        tag: _tag,
        data: {'errorType': errorType, 'userMessage': userMessage},
      );
    }
    
    return userMessage;
  }
  
  /// Handle no camera error (common in emulators)
  static Future<String> _handleNoCameraError() async {
    bool isEmulator = false;
    
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Check if running on emulator
        final result = await Process.run('getprop', ['ro.kernel.qemu']);
        isEmulator = result.stdout.toString().trim() == '1';
      }
    } catch (e) {
      // Ignore error, assume not emulator
    }
    
    if (isEmulator) {
      return 'Camera not available in emulator. Please use the gallery option to select images for editing.';
    } else {
      return 'No camera found on this device. Please use the gallery option to select images.';
    }
  }
  
  /// Handle camera capture failed error
  static Future<String> _handleCaptureFailedError() async {
    return 'Failed to capture photo. This might be due to insufficient storage or camera hardware issues. Try using the gallery option instead.';
  }
  
  /// Handle generic camera error with emulator detection
  static Future<String> _handleGenericCameraError(PlatformException error) async {
    bool isEmulator = false;
    
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final result = await Process.run('getprop', ['ro.kernel.qemu']);
        isEmulator = result.stdout.toString().trim() == '1';
      }
    } catch (e) {
      // Ignore error
    }
    
    if (isEmulator) {
      return 'Camera functionality is limited in emulator. Please use the gallery option to select images.';
    } else {
      return 'Camera error: ${error.message ?? 'Unknown error'}. Try using the gallery option instead.';
    }
  }
  
  /// Handle image processing errors
  static String handleImageProcessingError(dynamic error, {String? context}) {
    String userMessage = '';
    String errorType = '';
    
    if (kDebugMode) {
      DebugService.log(
        '🖼️ Image processing error occurred: $error',
        level: DebugLevel.error,
        tag: _tag,
        data: {'context': context, 'error': error.toString()},
      );
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('out of memory') || errorString.contains('memory')) {
      errorType = 'MEMORY_ERROR';
      userMessage = 'Image too large to process. Try selecting a smaller image or restart the app to free up memory.';
    } else if (errorString.contains('failed to decode') || errorString.contains('decode')) {
      errorType = 'DECODE_ERROR';
      userMessage = 'Invalid or corrupted image file. Please select a different image.';
    } else if (errorString.contains('file not found') || errorString.contains('does not exist')) {
      errorType = 'FILE_NOT_FOUND';
      userMessage = 'Image file not found. Please select the image again.';
    } else if (errorString.contains('permission denied') || errorString.contains('access denied')) {
      errorType = 'PERMISSION_ERROR';
      userMessage = 'Cannot access image file. Please check app permissions.';
    } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
      errorType = 'TIMEOUT_ERROR';
      userMessage = 'Image processing is taking too long. Try with a smaller image or restart the app.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      errorType = 'NETWORK_ERROR';
      userMessage = 'Network error during processing. Please check your internet connection.';
    } else {
      errorType = 'UNKNOWN_PROCESSING_ERROR';
      userMessage = 'Failed to process image. Please try again or select a different image.';
    }
    
    if (kDebugMode) {
      DebugService.log(
        '🔧 Image processing error handled: $errorType',
        level: DebugLevel.info,
        tag: _tag,
        data: {'errorType': errorType, 'userMessage': userMessage},
      );
    }
    
    return userMessage;
  }
  
  /// Handle file system errors
  static String handleFileSystemError(dynamic error, {String? context}) {
    String userMessage = '';
    String errorType = '';
    
    if (kDebugMode) {
      DebugService.log(
        '📁 File system error occurred: $error',
        level: DebugLevel.error,
        tag: _tag,
        data: {'context': context, 'error': error.toString()},
      );
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission denied') || errorString.contains('access denied')) {
      errorType = 'PERMISSION_ERROR';
      userMessage = 'Cannot access file. Please grant storage permissions in device settings.';
    } else if (errorString.contains('no space') || errorString.contains('storage full')) {
      errorType = 'STORAGE_FULL';
      userMessage = 'Insufficient storage space. Please free up some space and try again.';
    } else if (errorString.contains('file not found') || errorString.contains('does not exist')) {
      errorType = 'FILE_NOT_FOUND';
      userMessage = 'File not found. Please select the file again.';
    } else if (errorString.contains('read-only') || errorString.contains('write protected')) {
      errorType = 'READ_ONLY_ERROR';
      userMessage = 'Cannot save to this location. Storage may be read-only.';
    } else {
      errorType = 'UNKNOWN_FILE_ERROR';
      userMessage = 'File system error occurred. Please try again.';
    }
    
    if (kDebugMode) {
      DebugService.log(
        '🔧 File system error handled: $errorType',
        level: DebugLevel.info,
        tag: _tag,
        data: {'errorType': errorType, 'userMessage': userMessage},
      );
    }
    
    return userMessage;
  }
  
  /// Handle network errors
  static String handleNetworkError(dynamic error, {String? context}) {
    String userMessage = '';
    String errorType = '';
    
    if (kDebugMode) {
      DebugService.log(
        '🌐 Network error occurred: $error',
        level: DebugLevel.error,
        tag: _tag,
        data: {'context': context, 'error': error.toString()},
      );
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('no internet') || errorString.contains('network unreachable')) {
      errorType = 'NO_INTERNET';
      userMessage = 'No internet connection. Please check your network settings.';
    } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
      errorType = 'TIMEOUT';
      userMessage = 'Request timed out. Please check your internet connection and try again.';
    } else if (errorString.contains('server error') || errorString.contains('500')) {
      errorType = 'SERVER_ERROR';
      userMessage = 'Server error occurred. Please try again later.';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      errorType = 'UNAUTHORIZED';
      userMessage = 'Authentication failed. Please check your credentials.';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      errorType = 'FORBIDDEN';
      userMessage = 'Access denied. You may not have permission for this operation.';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      errorType = 'NOT_FOUND';
      userMessage = 'Requested resource not found.';
    } else {
      errorType = 'UNKNOWN_NETWORK_ERROR';
      userMessage = 'Network error occurred. Please check your connection and try again.';
    }
    
    if (kDebugMode) {
      DebugService.log(
        '🔧 Network error handled: $errorType',
        level: DebugLevel.info,
        tag: _tag,
        data: {'errorType': errorType, 'userMessage': userMessage},
      );
    }
    
    return userMessage;
  }
  
  /// Handle general application errors
  static String handleGeneralError(dynamic error, {String? context}) {
    String userMessage = '';
    String errorType = '';
    
    if (kDebugMode) {
      DebugService.log(
        '⚠️ General error occurred: $error',
        level: DebugLevel.error,
        tag: _tag,
        data: {'context': context, 'error': error.toString()},
      );
    }
    
    if (error is OutOfMemoryError) {
      errorType = 'OUT_OF_MEMORY';
      userMessage = 'App is running low on memory. Please restart the app.';
    } else if (error is StackOverflowError) {
      errorType = 'STACK_OVERFLOW';
      userMessage = 'App encountered a processing error. Please restart the app.';
    } else if (error is FormatException) {
      errorType = 'FORMAT_ERROR';
      userMessage = 'Invalid data format. Please try again with different input.';
    } else if (error is ArgumentError) {
      errorType = 'ARGUMENT_ERROR';
      userMessage = 'Invalid operation. Please try again.';
    } else if (error is StateError) {
      errorType = 'STATE_ERROR';
      userMessage = 'App is in an invalid state. Please restart the app.';
    } else {
      errorType = 'UNKNOWN_ERROR';
      userMessage = 'An unexpected error occurred. Please try again or restart the app.';
    }
    
    if (kDebugMode) {
      DebugService.log(
        '🔧 General error handled: $errorType',
        level: DebugLevel.info,
        tag: _tag,
        data: {'errorType': errorType, 'userMessage': userMessage},
      );
    }
    
    return userMessage;
  }
  
  /// Show error dialog with appropriate actions
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    if (kDebugMode) {
      DebugService.log(
        '💬 Showing error dialog: $title',
        level: DebugLevel.info,
        tag: _tag,
        data: {'title': title, 'message': message},
      );
    }
    
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181A1B),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF4A90E2), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF4A90E2)),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (kDebugMode) {
      DebugService.log(
        '📱 Showing error snackbar: $message',
        level: DebugLevel.info,
        tag: _tag,
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A90E2),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Handle and show camera error
  static Future<void> handleAndShowCameraError(
    BuildContext context,
    dynamic error, {
    String? customContext,
    bool useDialog = false,
  }) async {
    final message = await handleCameraError(error, context: customContext);
    
    if (useDialog) {
      showErrorDialog(
        context,
        'Camera Error',
        message,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Gallery', style: TextStyle(color: Color(0xFF4A90E2))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    } else {
      showErrorSnackBar(context, message);
    }
  }
  
  /// Handle and show image processing error
  static void handleAndShowImageProcessingError(
    BuildContext context,
    dynamic error, {
    String? customContext,
    bool useDialog = false,
  }) {
    final message = handleImageProcessingError(error, context: customContext);
    
    if (useDialog) {
      showErrorDialog(context, 'Processing Error', message);
    } else {
      showErrorSnackBar(context, message);
    }
  }
  
  /// Handle and show file system error
  static void handleAndShowFileSystemError(
    BuildContext context,
    dynamic error, {
    String? customContext,
    bool useDialog = false,
  }) {
    final message = handleFileSystemError(error, context: customContext);
    
    if (useDialog) {
      showErrorDialog(context, 'File Error', message);
    } else {
      showErrorSnackBar(context, message);
    }
  }
  
  /// Handle and show network error
  static void handleAndShowNetworkError(
    BuildContext context,
    dynamic error, {
    String? customContext,
    bool useDialog = false,
  }) {
    final message = handleNetworkError(error, context: customContext);
    
    if (useDialog) {
      showErrorDialog(context, 'Network Error', message);
    } else {
      showErrorSnackBar(context, message);
    }
  }
  
  /// Handle and show general error
  static void handleAndShowGeneralError(
    BuildContext context,
    dynamic error, {
    String? customContext,
    bool useDialog = false,
  }) {
    final message = handleGeneralError(error, context: customContext);
    
    if (useDialog) {
      showErrorDialog(context, 'Error', message);
    } else {
      showErrorSnackBar(context, message);
    }
  }
}
