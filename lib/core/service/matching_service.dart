import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get matches for current user
  Future<List<RoommateMatchModel>> getMatches() async {
    try {
      final userId = _client.auth.currentUser!.id;

      final response = await _client
          .from('matches')
          .select('''
            *,
            user_profiles!matches_user2_id_fkey(*)
          ''')
          .eq('user1_id', userId)
          .order('compatibility_score', ascending: false);

      return response.map<RoommateMatchModel>((json) {
        final profile = json['user_profiles'];
        return RoommateMatchModel(
          id: profile['id'],
          name: profile['name'],
          profileImage:
              profile['profile_image'] ??
              '/placeholder.svg?height=100&width=100',
          age: profile['age'],
          school: profile['school'],
          gender: profile['gender'],
          budget: 700.0, // This would come from questionnaire answers
          compatibilityScore: json['compatibility_score'],
          commonInterests: List<String>.from(json['common_interests'] ?? []),
          preferences:
              {}, // This would be calculated from questionnaire answers
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get matches: ${e.toString()}');
    }
  }

  // Calculate and create matches for a user
  Future<void> calculateMatches(String userId) async {
    try {
      // This is a simplified matching algorithm
      // In a real app, you'd have more sophisticated matching logic

      // Get all users except current user
      final users = await _client
          .from('user_profiles')
          .select()
          .neq('id', userId);

      // Get current user's answers
      final userAnswers = await _client
          .from('questionnaire_answers')
          .select()
          .eq('user_id', userId);

      final matches = <Map<String, dynamic>>[];

      for (final user in users) {
        // Get other user's answers
        final otherUserAnswers = await _client
            .from('questionnaire_answers')
            .select()
            .eq('user_id', user['id']);

        // Calculate compatibility score (simplified)
        final score = _calculateCompatibilityScore(
          userAnswers,
          otherUserAnswers,
        );

        if (score > 60) {
          // Only create matches above 60% compatibility
          matches.add({
            'user1_id': userId,
            'user2_id': user['id'],
            'compatibility_score': score,
            'common_interests': _findCommonInterests(
              userAnswers,
              otherUserAnswers,
            ),
          });
        }
      }

      // Delete existing matches
      await _client.from('matches').delete().eq('user1_id', userId);

      // Insert new matches
      if (matches.isNotEmpty) {
        await _client.from('matches').insert(matches);
      }
    } catch (e) {
      throw Exception('Failed to calculate matches: ${e.toString()}');
    }
  }

  // Simple compatibility score calculation
  int _calculateCompatibilityScore(
    List<dynamic> userAnswers,
    List<dynamic> otherUserAnswers,
  ) {
    if (userAnswers.isEmpty || otherUserAnswers.isEmpty) return 0;

    final userAnswersMap = <String, List<String>>{};
    final otherAnswersMap = <String, List<String>>{};

    for (final answer in userAnswers) {
      userAnswersMap[answer['question_id']] = List<String>.from(
        answer['answers'],
      );
    }

    for (final answer in otherUserAnswers) {
      otherAnswersMap[answer['question_id']] = List<String>.from(
        answer['answers'],
      );
    }

    int matches = 0;
    int totalQuestions = 0;

    for (final questionId in userAnswersMap.keys) {
      if (otherAnswersMap.containsKey(questionId)) {
        totalQuestions++;
        final userAnswerSet = userAnswersMap[questionId]!.toSet();
        final otherAnswerSet = otherAnswersMap[questionId]!.toSet();

        if (userAnswerSet.intersection(otherAnswerSet).isNotEmpty) {
          matches++;
        }
      }
    }

    return totalQuestions > 0 ? ((matches / totalQuestions) * 100).round() : 0;
  }

  // Find common interests from questionnaire answers
  List<String> _findCommonInterests(
    List<dynamic> userAnswers,
    List<dynamic> otherUserAnswers,
  ) {
    // This would look for the "hobbies/interests" question and find common answers
    // Simplified implementation
    return ['Gaming', 'Movies', 'Cooking']; // Placeholder
  }
}
