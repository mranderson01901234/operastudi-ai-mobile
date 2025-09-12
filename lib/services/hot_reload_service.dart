import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'debug_service.dart';

class HotReloadService {
  static const String _tag = 'HotReloadService';
  static bool _isInitialized = false;
  static final Map<String, dynamic> _persistentState = {};
  static final List<Function> _stateRestoreCallbacks = [];
  
  /// Initialize hot reload service
  static void initialize() {
    if (_isInitialized || !kDebugMode) return;
    
    _isInitialized = true;
    
    if (kDebugMode) {
      DebugService.log(
        '🔥 HotReloadService initialized',
        level: DebugLevel.info,
        tag: _tag,
      );
    }
  }
  
  /// Preserve state before hot reload
  static void preserveState(String key, dynamic value) {
    if (!kDebugMode) return;
    
    _persistentState[key] = value;
    
    if (kDebugMode) {
      DebugService.log(
        '💾 State preserved: $key',
        level: DebugLevel.debug,
        tag: _tag,
        data: {'key': key, 'valueType': value.runtimeType.toString()},
      );
    }
  }
  
  /// Restore state after hot reload
  static T? restoreState<T>(String key) {
    if (!kDebugMode) return null;
    
    final value = _persistentState[key];
    
    if (value is T) {
      if (kDebugMode) {
        DebugService.log(
          '🔄 State restored: $key',
          level: DebugLevel.debug,
          tag: _tag,
          data: {'key': key, 'valueType': value.runtimeType.toString()},
        );
      }
      return value;
    }
    
    return null;
  }
  
  /// Clear preserved state
  static void clearState([String? key]) {
    if (!kDebugMode) return;
    
    if (key != null) {
      _persistentState.remove(key);
      if (kDebugMode) {
        DebugService.log(
          '🗑️ State cleared: $key',
          level: DebugLevel.debug,
          tag: _tag,
        );
      }
    } else {
      _persistentState.clear();
      if (kDebugMode) {
        DebugService.log(
          '🗑️ All state cleared',
          level: DebugLevel.debug,
          tag: _tag,
        );
      }
    }
  }
  
  /// Register callback for state restoration
  static void registerStateRestoreCallback(Function callback) {
    if (!kDebugMode) return;
    
    _stateRestoreCallbacks.add(callback);
    
    if (kDebugMode) {
      DebugService.log(
        '📝 State restore callback registered',
        level: DebugLevel.debug,
        tag: _tag,
        data: {'callbackCount': _stateRestoreCallbacks.length},
      );
    }
  }
  
  /// Execute state restore callbacks
  static void executeStateRestoreCallbacks() {
    if (!kDebugMode) return;
    
    if (kDebugMode) {
      DebugService.log(
        '🔄 Executing state restore callbacks: ${_stateRestoreCallbacks.length}',
        level: DebugLevel.info,
        tag: _tag,
      );
    }
    
    for (final callback in _stateRestoreCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          DebugService.log(
            '❌ State restore callback failed: $e',
            level: DebugLevel.error,
            tag: _tag,
          );
        }
      }
    }
  }
  
  /// Get current preserved state
  static Map<String, dynamic> getCurrentState() {
    return Map.from(_persistentState);
  }
  
  /// Check if hot reload is supported
  static bool get isHotReloadSupported {
    return kDebugMode && !kIsWeb;
  }
  
  /// Get hot reload statistics
  static Map<String, dynamic> getHotReloadStats() {
    return {
      'isInitialized': _isInitialized,
      'isSupported': isHotReloadSupported,
      'preservedStateCount': _persistentState.length,
      'callbackCount': _stateRestoreCallbacks.length,
      'preservedKeys': _persistentState.keys.toList(),
    };
  }
}

/// Mixin for widgets that need hot reload state preservation
mixin HotReloadStateMixin<T extends StatefulWidget> on State<T> {
  String get hotReloadKey => '${widget.runtimeType}_$hashCode';
  
  /// Preserve widget state
  void preserveHotReloadState(Map<String, dynamic> state) {
    if (kDebugMode) {
      HotReloadService.preserveState(hotReloadKey, state);
    }
  }
  
  /// Restore widget state
  Map<String, dynamic>? restoreHotReloadState() {
    if (kDebugMode) {
      return HotReloadService.restoreState<Map<String, dynamic>>(hotReloadKey);
    }
    return null;
  }
  
  /// Clear widget state
  void clearHotReloadState() {
    if (kDebugMode) {
      HotReloadService.clearState(hotReloadKey);
    }
  }
  
  @override
  void dispose() {
    clearHotReloadState();
    super.dispose();
  }
}

/// Hot reload optimized state notifier
abstract class HotReloadOptimizedNotifier extends ChangeNotifier {
  String get notifierKey => runtimeType.toString();
  
  /// Preserve notifier state
  void preserveState() {
    if (kDebugMode) {
      final state = serializeState();
      if (state != null) {
        HotReloadService.preserveState(notifierKey, state);
      }
    }
  }
  
  /// Restore notifier state
  void restoreState() {
    if (kDebugMode) {
      final state = HotReloadService.restoreState<Map<String, dynamic>>(notifierKey);
      if (state != null) {
        deserializeState(state);
      }
    }
  }
  
  /// Serialize state for preservation (override in subclasses)
  Map<String, dynamic>? serializeState();
  
  /// Deserialize state for restoration (override in subclasses)
  void deserializeState(Map<String, dynamic> state);
  
  @override
  void dispose() {
    preserveState();
    super.dispose();
  }
}
