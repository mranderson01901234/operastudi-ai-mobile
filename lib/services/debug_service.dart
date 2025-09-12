import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'camera_service.dart';
import 'image_processor.dart';

class DebugService {
  static bool _isDebugMode = kDebugMode;
  static final List<DebugLog> _logs = [];
  static const int _maxLogs = 500;
  static File? _logFile;
  static bool _fileLoggingEnabled = true;
  
  // Debug overlay state
  static bool _showDebugOverlay = false;
  static final Map<String, dynamic> _debugInfo = {};
  
  /// Initialize debug service
  static Future<void> initialize() async {
    if (!_isDebugMode) return;
    
    try {
      await _initializeLogFile();
      await _logSystemInfo();
      log('🚀 DebugService: Initialized successfully', level: DebugLevel.info);
    } catch (e) {
      print('❌ DebugService: Failed to initialize: $e');
    }
  }
  
  /// Initialize log file for persistent logging
  static Future<void> _initializeLogFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File(path.join(logDir.path, 'debug_$timestamp.log'));
      
      await _logFile!.writeAsString('=== Selfie Editor Debug Log ===\n');
      await _logFile!.writeAsString('Started: ${DateTime.now()}\n\n', mode: FileMode.append);
      
    } catch (e) {
      print('⚠️ DebugService: Could not initialize log file: $e');
      _fileLoggingEnabled = false;
    }
  }
  
  /// Log system information
  static Future<void> _logSystemInfo() async {
    final info = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
    
    if (!kIsWeb) {
      info['platformVersion'] = Platform.operatingSystemVersion;
      info['numberOfProcessors'] = Platform.numberOfProcessors;
    }
    
    // Get camera info
    try {
      final cameraInfo = await CameraService.getCameraInfo();
      info['cameraInfo'] = cameraInfo;
    } catch (e) {
      info['cameraInfoError'] = e.toString();
    }
    
    // Get image processor stats
    info['imageProcessorStats'] = ImageProcessor.getProcessingStats();
    
    _debugInfo.addAll(info);
    
    log('📊 System Info: ${json.encode(info)}', level: DebugLevel.info);
  }
  
  /// Main logging function
  static void log(
    String message, {
    DebugLevel level = DebugLevel.debug,
    String? tag,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    if (!_isDebugMode) return;
    
    final logEntry = DebugLog(
      message: message,
      level: level,
      tag: tag,
      data: data,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
    
    // Add to memory logs
    _logs.add(logEntry);
    
    // Manage memory usage
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
    
    // Console output
    _printToConsole(logEntry);
    
    // File output
    if (_fileLoggingEnabled && _logFile != null) {
      _writeToFile(logEntry);
    }
  }
  
  /// Print log to console with colors and formatting
  static void _printToConsole(DebugLog log) {
    final prefix = _getLevelPrefix(log.level);
    final tag = log.tag != null ? '[${log.tag}] ' : '';
    final timestamp = log.timestamp.toString().substring(11, 19);
    
    final message = '$prefix [$timestamp] $tag${log.message}';
    
    // Use different print methods based on level
    switch (log.level) {
      case DebugLevel.error:
        debugPrint('🔴 $message');
        break;
      case DebugLevel.warning:
        debugPrint('🟡 $message');
        break;
      case DebugLevel.info:
        debugPrint('🔵 $message');
        break;
      case DebugLevel.debug:
        debugPrint('⚪ $message');
        break;
      case DebugLevel.verbose:
        if (kDebugMode) debugPrint('⚫ $message');
        break;
    }
    
    // Print additional data if present
    if (log.data != null && log.data!.isNotEmpty) {
      debugPrint('   📋 Data: ${json.encode(log.data)}');
    }
    
    // Print stack trace for errors
    if (log.stackTrace != null && log.level == DebugLevel.error) {
      debugPrint('   📍 Stack trace: ${log.stackTrace}');
    }
  }
  
  /// Write log to file
  static void _writeToFile(DebugLog log) {
    if (_logFile == null) return;
    
    try {
      final prefix = _getLevelPrefix(log.level);
      final tag = log.tag != null ? '[${log.tag}] ' : '';
      final line = '${log.timestamp} $prefix $tag${log.message}\n';
      
      _logFile!.writeAsString(line, mode: FileMode.append);
      
      if (log.data != null && log.data!.isNotEmpty) {
        _logFile!.writeAsString('  Data: ${json.encode(log.data)}\n', mode: FileMode.append);
      }
      
      if (log.stackTrace != null) {
        _logFile!.writeAsString('  Stack: ${log.stackTrace}\n', mode: FileMode.append);
      }
    } catch (e) {
      debugPrint('⚠️ DebugService: Failed to write to log file: $e');
    }
  }
  
  /// Get level prefix
  static String _getLevelPrefix(DebugLevel level) {
    switch (level) {
      case DebugLevel.error:
        return 'ERROR';
      case DebugLevel.warning:
        return 'WARN ';
      case DebugLevel.info:
        return 'INFO ';
      case DebugLevel.debug:
        return 'DEBUG';
      case DebugLevel.verbose:
        return 'VERB ';
    }
  }
  
  /// Log image processing operation
  static void logImageProcessing({
    required String operation,
    required String imagePath,
    required Duration duration,
    Map<String, dynamic>? parameters,
    String? error,
  }) {
    final data = <String, dynamic>{
      'operation': operation,
      'imagePath': imagePath,
      'durationMs': duration.inMilliseconds,
    };
    
    if (parameters != null) {
      data['parameters'] = parameters;
    }
    
    if (error != null) {
      data['error'] = error;
      log('❌ Image processing failed: $operation', 
          level: DebugLevel.error, 
          tag: 'ImageProcessor', 
          data: data);
    } else {
      log('✅ Image processing completed: $operation in ${duration.inMilliseconds}ms', 
          level: DebugLevel.info, 
          tag: 'ImageProcessor', 
          data: data);
    }
  }
  
  /// Log camera operation
  static void logCameraOperation({
    required String operation,
    required bool success,
    String? error,
    Map<String, dynamic>? data,
  }) {
    final logData = <String, dynamic>{
      'operation': operation,
      'success': success,
    };
    
    if (data != null) {
      logData.addAll(data);
    }
    
    if (error != null) {
      logData['error'] = error;
    }
    
    final message = success 
        ? '✅ Camera operation completed: $operation'
        : '❌ Camera operation failed: $operation';
    
    log(message, 
        level: success ? DebugLevel.info : DebugLevel.error, 
        tag: 'CameraService', 
        data: logData);
  }
  
  /// Log app state change
  static void logStateChange({
    required String state,
    required String from,
    required String to,
    Map<String, dynamic>? data,
  }) {
    final logData = <String, dynamic>{
      'state': state,
      'from': from,
      'to': to,
    };
    
    if (data != null) {
      logData.addAll(data);
    }
    
    log('🔄 State change: $state ($from → $to)', 
        level: DebugLevel.debug, 
        tag: 'AppState', 
        data: logData);
  }
  
  /// Log performance metrics
  static void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metrics,
  }) {
    final data = <String, dynamic>{
      'operation': operation,
      'durationMs': duration.inMilliseconds,
    };
    
    if (metrics != null) {
      data.addAll(metrics);
    }
    
    String level = '🟢';
    DebugLevel logLevel = DebugLevel.info;
    
    if (duration.inMilliseconds > 5000) {
      level = '🔴';
      logLevel = DebugLevel.warning;
    } else if (duration.inMilliseconds > 1000) {
      level = '🟡';
      logLevel = DebugLevel.info;
    }
    
    log('$level Performance: $operation took ${duration.inMilliseconds}ms', 
        level: logLevel, 
        tag: 'Performance', 
        data: data);
  }
  
  /// Get recent logs
  static List<DebugLog> getRecentLogs({int count = 50}) {
    if (_logs.length <= count) return List.from(_logs);
    return _logs.sublist(_logs.length - count);
  }
  
  /// Get logs by level
  static List<DebugLog> getLogsByLevel(DebugLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }
  
  /// Export logs to file
  static Future<File?> exportLogs() async {
    if (!_isDebugMode || _logs.isEmpty) return null;
    
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFile = File(path.join(tempDir.path, 'debug_export_$timestamp.json'));
      
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'debugInfo': _debugInfo,
        'logs': _logs.map((log) => log.toJson()).toList(),
      };
      
      await exportFile.writeAsString(json.encode(exportData));
      
      log('📤 Logs exported to: ${exportFile.path}', level: DebugLevel.info);
      return exportFile;
      
    } catch (e) {
      log('❌ Failed to export logs: $e', level: DebugLevel.error);
      return null;
    }
  }
  
  /// Clear logs
  static void clearLogs() {
    _logs.clear();
    log('🧹 Debug logs cleared', level: DebugLevel.info);
  }
  
  /// Toggle debug overlay
  static void toggleDebugOverlay() {
    _showDebugOverlay = !_showDebugOverlay;
    log('👁️ Debug overlay ${_showDebugOverlay ? 'enabled' : 'disabled'}', 
        level: DebugLevel.info);
  }
  
  /// Get debug overlay state
  static bool get showDebugOverlay => _showDebugOverlay && _isDebugMode;
  
  /// Update debug info
  static void updateDebugInfo(String key, dynamic value) {
    _debugInfo[key] = value;
  }
  
  /// Get debug info
  static Map<String, dynamic> get debugInfo => Map.from(_debugInfo);
  
  /// Check if debug mode is enabled
  static bool get isDebugMode => _isDebugMode;
  
  /// Set debug mode (for testing)
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }
}

/// Debug log levels
enum DebugLevel {
  error,
  warning,
  info,
  debug,
  verbose,
}

/// Debug log entry
class DebugLog {
  final String message;
  final DebugLevel level;
  final String? tag;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  
  DebugLog({
    required this.message,
    required this.level,
    this.tag,
    this.data,
    required this.timestamp,
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.toString(),
      'tag': tag,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}
