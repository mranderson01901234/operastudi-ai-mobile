import 'lib/services/auth_service.dart';

void main() {
  print('🧪 Testing Email Validation...');
  
  // Test valid emails
  final validEmails = [
    'admin@gmail.com',
    'test@example.com',
    'user.name@domain.co.uk',
    'user+tag@example.org',
    'user123@test-domain.com'
  ];
  
  // Test invalid emails
  final invalidEmails = [
    'invalid-email',
    '@domain.com',
    'user@',
    'user..name@domain.com',
    'user@domain',
    'user@.domain.com',
    'user@domain..com'
  ];
  
  print('\n✅ Testing Valid Emails:');
  for (final email in validEmails) {
    final isValid = AuthService.isValidEmail(email);
    print('   $email: ${isValid ? "✅ VALID" : "❌ INVALID"}');
  }
  
  print('\n❌ Testing Invalid Emails:');
  for (final email in invalidEmails) {
    final isValid = AuthService.isValidEmail(email);
    print('   $email: ${isValid ? "❌ SHOULD BE INVALID" : "✅ CORRECTLY INVALID"}');
  }
  
  print('\n🎯 Testing admin@gmail.com specifically:');
  final adminEmail = 'admin@gmail.com';
  final adminValid = AuthService.isValidEmail(adminEmail);
  print('   $adminEmail: ${adminValid ? "✅ VALID" : "❌ INVALID"}');
  
  print('\n✅ Email validation test completed!');
}
