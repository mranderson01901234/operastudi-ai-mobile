import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static Future<bool> signInWithEmail(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response.user != null;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  static Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user profile with 10 credits
        await Supabase.instance.client
            .from('users')
            .insert({
              'id': response.user!.id,
              'email': email,
              'credits_remaining': 10,
              'created_at': DateTime.now().toIso8601String(),
            });
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  static User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  static bool get isSignedIn => getCurrentUser() != null;

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
      print('Get user profile error: $e');
      return null;
    }
  }
}
