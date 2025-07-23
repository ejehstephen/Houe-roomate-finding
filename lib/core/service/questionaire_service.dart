import 'package:camp_nest/core/model/questionnaire.dart';
import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionnaireService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Add getter for client access
  SupabaseClient get client => _client;

  // Get all questionnaire questions
  Future<List<QuestionnaireQuestion>> getQuestions() async {
    try {
      final response = await _client
          .from('questionnaire_questions')
          .select()
          .eq('is_active', true)
          .order('order_index');

      return response.map<QuestionnaireQuestion>((json) {
        return QuestionnaireQuestion(
          id: json['id'],
          question: json['question'],
          options: List<String>.from(json['options']),
          type: json['question_type'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get questions: ${e.toString()}');
    }
  }

  // Save user's answers using upsert to handle duplicates
  Future<void> saveAnswers(Map<String, QuestionnaireAnswer> answers) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use upsert instead of delete + insert to handle duplicates
      final answersToUpsert =
          answers.values
              .map(
                (answer) => {
                  'user_id': userId,
                  'question_id': answer.questionId,
                  'answers': answer.answers,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      // Use upsert with onConflict to update existing records
      await _client
          .from('questionnaire_answers')
          .upsert(
            answersToUpsert,
            onConflict:
                'user_id,question_id', // Specify the unique constraint columns
          );
    } catch (e) {
      throw Exception('Failed to save answers: ${e.toString()}');
    }
  }

  // Alternative method: Save answers one by one with individual upserts
  Future<void> saveAnswersIndividually(
    Map<String, QuestionnaireAnswer> answers,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Save each answer individually to avoid batch conflicts
      for (final answer in answers.values) {
        await _client.from('questionnaire_answers').upsert({
          'user_id': userId,
          'question_id': answer.questionId,
          'answers': answer.answers,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to save answers: ${e.toString()}');
    }
  }

  // Get user's answers
  Future<Map<String, QuestionnaireAnswer>> getUserAnswers(String userId) async {
    try {
      final response = await _client
          .from('questionnaire_answers')
          .select()
          .eq('user_id', userId);

      final Map<String, QuestionnaireAnswer> answers = {};
      for (final json in response) {
        final answer = QuestionnaireAnswer(
          questionId: json['question_id'],
          answers: List<String>.from(json['answers']),
        );
        answers[json['question_id']] = answer;
      }

      return answers;
    } catch (e) {
      throw Exception('Failed to get user answers: ${e.toString()}');
    }
  }

  // Check if user has completed questionnaire
  Future<bool> hasUserCompletedQuestionnaire(String userId) async {
    try {
      final response = await _client
          .from('questionnaire_answers')
          .select('question_id')
          .eq('user_id', userId);

      final questionsResponse = await _client
          .from('questionnaire_questions')
          .select('id')
          .eq('is_active', true);

      return response.length == questionsResponse.length;
    } catch (e) {
      return false;
    }
  }
}
