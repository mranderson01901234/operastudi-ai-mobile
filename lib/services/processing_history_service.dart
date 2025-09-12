import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessingHistoryService {
  static Future<void> addProcessingRecord({
    required String processingType,
    required int creditsConsumed,
    required String status,
    String? resultUrl,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('processing_history').insert({
      'user_id': user.id,
      'image_name': 'mobile_upload_${DateTime.now().millisecondsSinceEpoch}',
      'processing_type': processingType,
      'enhancement_settings': {
        'scale': '2x',
        'sharpen': 37,
        'denoise': 25,
        'model_name': 'real image denoising'
      },
      'credits_consumed': creditsConsumed,
      'status': status,
      'result_url': resultUrl,
    });
  }

  static Future<List<Map<String, dynamic>>> getUserHistory({int limit = 20}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('processing_history')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
