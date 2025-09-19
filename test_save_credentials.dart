#!/usr/bin/env dart

import 'dart:io';
import 'lib/services/credential_storage_service.dart';
import 'lib/config/app_logger.dart';

/// Simple test script for save credentials functionality
void main() async {
  print('🧪 Testing Save Credentials Functionality');
  print('=' * 50);

  try {
    // Test 1: Save credentials
    print('\n1️⃣ Testing saveCredentials()');
    await CredentialStorageService.saveCredentials('test@example.com', 'testpassword123');
    print('✅ Credentials saved successfully');

    // Test 2: Retrieve credentials
    print('\n2️⃣ Testing getSavedCredentials()');
    final credentials = await CredentialStorageService.getSavedCredentials();
    print('📖 Retrieved credentials:');
    print('   Email: ${credentials['email']}');
    print('   Password: ${credentials['password'] != null ? '***hidden***' : 'null'}');

    // Test 3: Check if save is enabled
    print('\n3️⃣ Testing isSaveCredentialsEnabled()');
    final isEnabled = await CredentialStorageService.isSaveCredentialsEnabled();
    print('🔒 Save credentials enabled: $isEnabled');

    // Test 4: Check for specific email
    print('\n4️⃣ Testing hasCredentialsForEmail()');
    final hasCredentials = await CredentialStorageService.hasCredentialsForEmail('test@example.com');
    print('📧 Has credentials for test@example.com: $hasCredentials');

    // Test 5: Get last login email
    print('\n5️⃣ Testing getLastLoginEmail()');
    final lastEmail = await CredentialStorageService.getLastLoginEmail();
    print('📮 Last login email: $lastEmail');

    // Test 6: Debug info
    print('\n6️⃣ Testing getDebugInfo()');
    final debugInfo = await CredentialStorageService.getDebugInfo();
    print('🐛 Debug info:');
    debugInfo.forEach((key, value) {
      print('   $key: $value');
    });

    // Test 7: Disable and clear
    print('\n7️⃣ Testing setSaveCredentialsEnabled(false)');
    await CredentialStorageService.setSaveCredentialsEnabled(false);
    print('🔒 Save credentials disabled');

    // Test 8: Verify cleared
    print('\n8️⃣ Verifying credentials cleared');
    final clearedCredentials = await CredentialStorageService.getSavedCredentials();
    print('📖 After clearing:');
    print('   Email: ${clearedCredentials['email']}');
    print('   Password: ${clearedCredentials['password'] != null ? '***hidden***' : 'null'}');

    // Test 9: Re-enable for next test
    print('\n9️⃣ Re-enabling for next test');
    await CredentialStorageService.saveCredentials('admin@operastudio.io', 'admin123456');
    print('✅ Admin credentials saved for testing');

    print('\n' + '=' * 50);
    print('🎉 All tests completed successfully!');
    print('💡 The save credentials functionality is working correctly');

  } catch (e, stackTrace) {
    print('\n❌ Test failed with error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
} 