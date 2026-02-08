import 'package:camp_nest/core/model/questionnaire.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionnaireService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<QuestionnaireQuestion>> getQuestions() async {
    try {
      final response = await _client
          .from('questionnaire_questions')
          .select('*, question_options(options)');

      final data = response as List<dynamic>;
      return data.map((json) {
        final map = Map<String, dynamic>.from(json);
        if (map['question_options'] is List) {
          map['options'] =
              (map['question_options'] as List)
                  .map((e) => e['options']?.toString() ?? '')
                  .toList();
        }
        return QuestionnaireQuestion.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error fetching questions: $e');
      throw Exception('Failed to fetch questions');
    }
  }

  // Returns Map<QuestionId, Answer>
  Future<Map<String, QuestionnaireAnswer>> getUserAnswers(String userId) async {
    try {
      // If 'current', use auth user
      var targetId = userId;
      if (userId == 'current') {
        final u = _client.auth.currentUser;
        if (u == null) return {};
        targetId = u.id;
      }

      final response = await _client
          .from('questionnaire_answers')
          .select('*, answer_values(answers)')
          .eq('user_id', targetId);

      final data = response as List<dynamic>;
      final Map<String, QuestionnaireAnswer> result = {};

      for (var json in data) {
        final map = Map<String, dynamic>.from(json);
        List<String> answerList = [];
        if (map['answer_values'] is List) {
          answerList =
              (map['answer_values'] as List)
                  .map((e) => e['answers']?.toString() ?? '')
                  .toList();
        }
        // Fallback to text column
        if (answerList.isEmpty &&
            map['text'] != null &&
            map['text'].toString().isNotEmpty) {
          answerList.add(map['text']);
        }

        final qId = map['question_id'].toString();
        result[qId] = QuestionnaireAnswer(questionId: qId, answers: answerList);
      }
      return result;
    } catch (e) {
      print('Error fetching answers: $e');
      return {};
    }
  }

  // Accepts Map
  Future<void> saveAnswers(Map<String, QuestionnaireAnswer> answers) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Delete old answers
      await _client
          .from('questionnaire_answers')
          .delete()
          .eq('user_id', user.id);

      // Insert new
      // We can do this in parallel or batch if possible, but loop is simple
      for (var answer in answers.values) {
        final mainText = answer.answers.isNotEmpty ? answer.answers.first : '';

        final res =
            await _client
                .from('questionnaire_answers')
                .insert({
                  'user_id': user.id,
                  'question_id': answer.questionId,
                  'text': mainText,
                })
                .select()
                .single();

        final answerId = res['id'];

        if (answer.answers.isNotEmpty) {
          await _client
              .from('answer_values')
              .insert(
                answer.answers
                    .map((val) => {'answer_id': answerId, 'answers': val})
                    .toList(),
              );
        }
      }
    } catch (e) {
      print('Error saving answers: $e');
      throw Exception('Failed to save answers');
    }
  }

  Future<void> saveAnswersIndividually(
    Map<String, QuestionnaireAnswer> answers,
  ) async {
    // Just call saveAnswers for now as fallback
    await saveAnswers(answers);
  }

  Future<bool> hasUserCompletedQuestionnaire(String userId) async {
    // Check if user has answered a sufficient number of questions?
    // Or just if they have ANY answers?
    // Typically if they have > 0 answers we consider it started/completed for MVP.
    // To be precise we should check against question count.
    // For now, return true if count > 0.

    try {
      var targetId = userId;
      if (userId == 'current') {
        final u = _client.auth.currentUser;
        if (u == null) return false;
        targetId = u.id;
      }

      final res = await _client
          .from('questionnaire_answers')
          .select('id')
          .eq('user_id', targetId)
          .limit(1); // Just need one

      return (res as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
