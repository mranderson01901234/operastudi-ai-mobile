import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessingHistoryService {
  // ✅ ENHANCED: Add processing record with complete metadata
  static Future<void> addProcessingRecord({
    required String processingType,
    required int creditsConsumed,
    required String status,
    String? resultUrl,
    String? originalImageUrl,
    Map<String, dynamic>? enhancementSettings,
    double? processingTimeSeconds,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('processing_history').insert({
        'user_id': user.id,
        'image_name': 'enhancement_${DateTime.now().millisecondsSinceEpoch}',
        'processing_type': processingType,
        'enhancement_settings': enhancementSettings ?? {
          'scale': 2,
          'sharpen': 37,
          'denoise': 25,
          'model_name': 'real image denoising'
        },
        'credits_consumed': creditsConsumed,
        'status': status,
        'result_url': resultUrl,
        'original_image_url': originalImageUrl,
        'processing_time_seconds': processingTimeSeconds,
      });
    } catch (e) {
      print('❌ Error adding processing record: $e');
      // Don't throw - this shouldn't break the main flow
    }
  }

  // ✅ FIXED: Get user history with simplified query structure
  static Future<List<Map<String, dynamic>>> getUserHistory({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? processingType,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      // Build query in one chain for older Supabase version
      final response = await Supabase.instance.client
          .from('processing_history')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Filter results in memory if needed (for older Supabase version)
      List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response);
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        results = results.where((record) => 
          (record['image_name'] ?? '').toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      if (processingType != null && processingType.isNotEmpty) {
        results = results.where((record) => 
          record['processing_type'] == processingType
        ).toList();
      }

      return results;
    } catch (e) {
      print('❌ Error getting user history: $e');
      return [];
    }
  }

  // ✅ NEW: Get processing statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await Supabase.instance.client
          .from('processing_history')
          .select('processing_type, credits_consumed, created_at')
          .eq('user_id', user.id)
          .eq('status', 'completed');

      int totalEnhancements = response.length;
      int totalCreditsUsed = response.fold(0, (sum, record) => sum + (record['credits_consumed'] ?? 0));
      
      // Count by processing type
      Map<String, int> typeCounts = {};
      for (var record in response) {
        String type = record['processing_type'] ?? 'unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      return {
        'total_enhancements': totalEnhancements,
        'total_credits_used': totalCreditsUsed,
        'type_counts': typeCounts,
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {};
    }
  }

  // ✅ NEW: Delete processing record
  static Future<bool> deleteProcessingRecord(String recordId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      await Supabase.instance.client
          .from('processing_history')
          .delete()
          .eq('id', recordId)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      print('❌ Error deleting processing record: $e');
      return false;
    }
  }
}
