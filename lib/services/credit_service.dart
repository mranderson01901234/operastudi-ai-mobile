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
}
