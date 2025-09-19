import '../config/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreditService {
  static Future<Map<String, dynamic>> getUserCredits() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await Supabase.instance.client
        .from('users')
        .select('credits_remaining, subscription_tier')
        .eq('id', user.id)
        .single();

    return {
      'credits_remaining': response['credits_remaining'] ?? 0,
      'subscription_tier': response['subscription_tier'] ?? 'free',
    };
  }

  static Future<void> updateCredits(int creditsConsumed) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.rpc('update_user_credits', params: {
      'user_id': user.id,
      'credits_consumed': creditsConsumed,
    });
  }

  static Future<void> addCredits(int credits) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await Supabase.instance.client.rpc('add_user_credits', params: {
      'user_id': user.id,
      'credits_to_add': credits,
    });
  }

  static Future<void> consumeCredits(int credits) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await Supabase.instance.client.rpc('update_user_credits', params: {
      'user_id': user.id,
      'credits_consumed': credits,
    });
  }

  // Add missing deductCredits method
  Future<bool> deductCredits(int amount) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      
      // Get current credits
      final response = await Supabase.instance.client
          .from('users')
          .select('credits_remaining')
          .eq('id', user.id)
          .single();
      
      int currentCredits = response['credits_remaining'] ?? 0;
      
      if (currentCredits < amount) {
        return false; // Insufficient credits
      }
      
      // Deduct credits
      await Supabase.instance.client
          .from('users')
          .update({
            'credits_remaining': currentCredits - amount,
            'total_credits_used': currentCredits - amount, // Simple increment
          })
          .eq('id', user.id);
      
      return true;
    } catch (e) {
      AppLogger.error('Credit deduction error', e);
      return false;
    }
  }
}
