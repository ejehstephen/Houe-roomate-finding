import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Called after questionnaire completion (no-op, matching is live via RPC).
  Future<void> calculateMatches(String userId) async {
    return;
  }

  /// Get matches for the current user via the server-side PostgreSQL function.
  /// This is a single RPC call that replaces 50+ sequential queries.
  Future<List<RoommateMatchModel>> getMatches() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final response = await _client.rpc('get_roommate_matches');

      if (response == null) return [];

      final data = response as List<dynamic>;
      return data
          .map((e) => RoommateMatchModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Matching RPC error: $e');
      throw Exception('Failed to calculate matches: $e');
    }
  }
}
