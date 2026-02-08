import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingService {
  final SupabaseClient _client = Supabase.instance.client;

  // Calculate matches for a user (or current user)
  // Since we are doing client-side calculations, this might just return void
  // or could store matches in a table if we wanted persistence.
  // For migration MVP, we'll calculate on demand in getMatches,
  // so this can be a no-op or trigger a pre-fetch.
  Future<void> calculateMatches(String userId) async {
    // Optional: Pre-calculate and save to a 'matches' table?
    // For now, doing nothing as we calculate live.
    return;
  }

  // Get matches for current user
  Future<List<RoommateMatchModel>> getMatches() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // 1. Fetch Current User Profile
      final userResponse =
          await _client
              .from('users')
              .select()
              .eq('id', currentUser.id)
              .single();
      final userProfile = UserModel.fromJson(userResponse);

      // 2. Fetch User's Questionnaire Answers
      final myAnswers = await _fetchAnswers(currentUser.id);

      // Apartment Status Check
      final apartmentQuestionId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      final myApartmentAnswers = myAnswers[apartmentQuestionId] ?? [];
      final myApartmentStatus =
          myApartmentAnswers.contains('Yes') ? 'Yes' : 'No';

      // 3. Fetch Candidates (Prioritize Same School)
      // Restricted: Only fetch users from the same school as per user request.

      final candidatesResponse = await _client
          .from('users')
          .select()
          .neq('id', currentUser.id)
          .eq('school', userProfile.school)
          .limit(20);

      // Previously had fallback here, removed to strictly enforce school matching.

      final candidates =
          (candidatesResponse as List<dynamic>)
              .map((e) => UserModel.fromJson(e))
              .toList();

      List<RoommateMatchModel> matches = [];

      // 4. Algorithm Loop
      for (var candidate in candidates) {
        // Fetch candidate answers
        // Note: N+1 query problem here. In production, fetch ALL answers in one go.
        // For MVP with <100 users, this is okay.
        // Better: fetch all answers where user_id in (candidates ids).
        final candidateAnswers = await _fetchAnswers(candidate.id);

        // Apartment Status Matching (Supply/Demand)
        final candidateAptAnswers = candidateAnswers[apartmentQuestionId] ?? [];
        final candidateStatus =
            candidateAptAnswers.contains('Yes') ? 'Yes' : 'No';

        // Skip if statuses are the same (e.g., both have apartments or both need them)
        if (myApartmentStatus == candidateStatus) continue;

        final score = _calculateCompatibilityScore(
          userProfile,
          myAnswers,
          candidate,
          candidateAnswers,
        );

        // WhatsApp Link Generation logic moved to UI or computed from phoneNumber on demand

        matches.add(
          RoommateMatchModel(
            id:
                candidate
                    .id, // Using UserID as Match ID for simplicity in this view
            name: candidate.name,
            age: candidate.age,
            gender: candidate.gender,
            school: candidate.school,
            compatibilityScore: score.round(), // int
            profileImage: candidate.profileImage ?? '',
            // whatsappLink removed; using phoneNumber instead
            phoneNumber: candidate.phoneNumber,
            commonInterests: _findCommonInterests(myAnswers, candidateAnswers),
            budget: 0.0, // Default as not in UserModel
            preferences: Map.fromIterable(
              candidate.preferences,
              key: (e) => e.toString(),
              value: (e) => 'true',
            ),
          ),
        );
      }

      // 5. Sort by Score Descending
      matches.sort(
        (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
      );

      // Return only top 5 matches
      return matches.take(5).toList();
    } catch (e) {
      print('Matching error: $e');
      throw Exception('Failed to calculate matches');
    }
  }

  // Helper: Fetch answers
  Future<Map<String, List<String>>> _fetchAnswers(String userId) async {
    final response = await _client
        .from('questionnaire_answers')
        .select('*, answer_values(answers)')
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    Map<String, List<String>> result = {};

    for (var json in data) {
      final map = Map<String, dynamic>.from(json);
      List<String> answerList = [];
      if (map['answer_values'] is List) {
        answerList =
            (map['answer_values'] as List)
                .map((e) => e['answers']?.toString() ?? '')
                .toList();
      }
      if (answerList.isEmpty &&
          map['text'] != null &&
          map['text'].toString().isNotEmpty) {
        answerList.add(map['text']);
      }
      result[map['question_id'].toString()] = answerList;
    }
    return result;
  }

  // Helper: Calculate Score
  double _calculateCompatibilityScore(
    UserModel me,
    Map<String, List<String>> myAnswers,
    UserModel them,
    Map<String, List<String>> theirAnswers,
  ) {
    double score = 0;

    // 1. School (High weight)
    if (me.school == them.school) score += 30;

    // 2. Gender Preference check
    // If I strictly prefer same gender:
    // This logic depends on "preferences" field in user or answers.
    // Simplifying: +10 for same gender
    if (me.gender == them.gender) score += 10;

    // 3. Questionnaire Answers Overlap
    // Intersection of answers
    // Define weights for specific question IDs if known, else generic overlap

    int overlapCount = 0;
    int totalMyAnswers = 0;

    myAnswers.forEach((qId, myAnsList) {
      totalMyAnswers += myAnsList.length;
      final theirAnsList = theirAnswers[qId];
      if (theirAnsList != null) {
        // Count intersecting elements
        final common = myAnsList.toSet().intersection(theirAnsList.toSet());
        overlapCount += common.length;
      }
    });

    // Normalize interest score
    if (totalMyAnswers > 0) {
      double interestRatio = overlapCount / totalMyAnswers;
      score += interestRatio * 60; // Max 60 points for interests
    }

    return score.clamp(0, 100);
  }

  List<String> _findCommonInterests(
    Map<String, List<String>> myAnswers,
    Map<String, List<String>> theirAnswers,
  ) {
    Set<String> common = {};
    myAnswers.forEach((qId, myAnsList) {
      final theirAnsList = theirAnswers[qId];
      if (theirAnsList != null) {
        common.addAll(myAnsList.toSet().intersection(theirAnsList.toSet()));
      }
    });
    return common.toList();
  }
}
