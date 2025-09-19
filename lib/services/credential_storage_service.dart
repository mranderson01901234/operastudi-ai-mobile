import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_logger.dart';

class CredentialStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _saveCredentialsKey = 'save_credentials_enabled';
  static const String _lastLoginEmailKey = 'last_login_email';

  /// Save user credentials securely
  static Future<void> saveCredentials(String email, String password) async {
    try {
      AppLogger.info('💾 Saving credentials for email: $email');
      
      await _storage.write(key: _emailKey, value: email.trim().toLowerCase());
      await _storage.write(key: _passwordKey, value: password);
      await _storage.write(key: _saveCredentialsKey, value: 'true');
      await _storage.write(key: _lastLoginEmailKey, value: email.trim().toLowerCase());
      
      AppLogger.info('✅ Credentials saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save credentials', e);
      rethrow;
    }
  }

  /// Retrieve saved credentials
  static Future<Map<String, String?>> getSavedCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      final saveEnabled = await _storage.read(key: _saveCredentialsKey);
      
      if (saveEnabled == 'true' && email != null && password != null) {
        AppLogger.info('📖 Retrieved saved credentials for: $email');
        return {
          'email': email,
          'password': password,
        };
      }
      
      return {
        'email': null,
        'password': null,
      };
    } catch (e) {
      AppLogger.error('Failed to retrieve credentials', e);
      return {
        'email': null,
        'password': null,
      };
    }
  }

  /// Check if save credentials is enabled
  static Future<bool> isSaveCredentialsEnabled() async {
    try {
      final saveEnabled = await _storage.read(key: _saveCredentialsKey);
      return saveEnabled == 'true';
    } catch (e) {
      AppLogger.error('Failed to check save credentials status', e);
      return false;
    }
  }

  /// Get last login email (for auto-fill even if password not saved)
  static Future<String?> getLastLoginEmail() async {
    try {
      return await _storage.read(key: _lastLoginEmailKey);
    } catch (e) {
      AppLogger.error('Failed to get last login email', e);
      return null;
    }
  }

  /// Update last login email
  static Future<void> updateLastLoginEmail(String email) async {
    try {
      await _storage.write(key: _lastLoginEmailKey, value: email.trim().toLowerCase());
    } catch (e) {
      AppLogger.error('Failed to update last login email', e);
    }
  }

  /// Clear all saved credentials
  static Future<void> clearSavedCredentials() async {
    try {
      AppLogger.info('🗑️ Clearing saved credentials');
      
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      await _storage.write(key: _saveCredentialsKey, value: 'false');
      
      AppLogger.info('✅ Credentials cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear credentials', e);
      rethrow;
    }
  }

  /// Enable or disable credential saving
  static Future<void> setSaveCredentialsEnabled(bool enabled) async {
    try {
      await _storage.write(key: _saveCredentialsKey, value: enabled.toString());
      
      if (!enabled) {
        // If disabling, clear the saved credentials
        await _storage.delete(key: _emailKey);
        await _storage.delete(key: _passwordKey);
        AppLogger.info('🔒 Save credentials disabled and cleared');
      }
    } catch (e) {
      AppLogger.error('Failed to set save credentials preference', e);
      rethrow;
    }
  }

  /// Check if credentials exist for a specific email
  static Future<bool> hasCredentialsForEmail(String email) async {
    try {
      final savedEmail = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      final saveEnabled = await _storage.read(key: _saveCredentialsKey);
      
      return saveEnabled == 'true' && 
             savedEmail != null && 
             password != null && 
             savedEmail.toLowerCase() == email.trim().toLowerCase();
    } catch (e) {
      AppLogger.error('Failed to check credentials for email', e);
      return false;
    }
  }

  /// Get all stored data for debugging (passwords excluded)
  static Future<Map<String, String?>> getDebugInfo() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final saveEnabled = await _storage.read(key: _saveCredentialsKey);
      final lastEmail = await _storage.read(key: _lastLoginEmailKey);
      
      return {
        'saved_email': email,
        'save_enabled': saveEnabled,
        'last_login_email': lastEmail,
        'has_password': (await _storage.read(key: _passwordKey)) != null ? 'yes' : 'no',
      };
    } catch (e) {
      AppLogger.error('Failed to get debug info', e);
      return {};
    }
  }
} 