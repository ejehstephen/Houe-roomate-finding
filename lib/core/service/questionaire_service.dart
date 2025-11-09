import 'dart:convert';
import 'package:camp_nest/core/model/questionnaire.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:http/http.dart' as http;

class QuestionnaireService {
  // GET /api/matches/questions
  Future<List<QuestionnaireQuestion>> getQuestions() async {
    final auth = AuthService();
    final baseUrl = auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/questions');

    final token = await auth.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(uri, headers: headers);
    print('GET /api/matches/questions ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list =
          data is List
              ? data
              : (data is Map<String, dynamic> && data['questions'] is List
                  ? data['questions']
                  : []);

      return list
          .map<QuestionnaireQuestion>(
            (e) => QuestionnaireQuestion.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load questions: ${resp.statusCode} ${resp.body}',
    );
  }

  // POST /api/matches/answers
  Future<void> saveAnswers(Map<String, QuestionnaireAnswer> answers) async {
    final auth = AuthService();
    final baseUrl = auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/answers');

    final token = await auth.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final payload = answers.values.map((a) => a.toJson()).toList();
    final body = jsonEncode(payload);

    print('POST /api/matches/answers request body: ' + body);
    final resp = await http.post(uri, headers: headers, body: body);
    print('POST /api/matches/answers ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) {
      return;
    }

    throw Exception('Failed to save answers: ${resp.statusCode} ${resp.body}');
  }

  // POST /api/matches/answers (fallback single-item)
  Future<void> saveAnswersIndividually(
    Map<String, QuestionnaireAnswer> answers,
  ) async {
    final auth = AuthService();
    final baseUrl = auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/answers');

    final token = await auth.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    for (final a in answers.values) {
      final body = jsonEncode([a.toJson()]);
      print('POST /api/matches/answers (single) request body: ' + body);
      final resp = await http.post(uri, headers: headers, body: body);
      print('POST /api/matches/answers (single) ${resp.statusCode}: ${resp.body}');

      if (!(resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204)) {
        throw Exception('Failed to save answer for ${a.questionId}: ${resp.statusCode} ${resp.body}');
      }
    }
  }

  // GET /api/matches/answers (user inferred from token)
  Future<Map<String, QuestionnaireAnswer>> getUserAnswers(String userId) async {
    final auth = AuthService();
    final baseUrl = auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/answers');

    final token = await auth.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(uri, headers: headers);
    print('GET /api/matches/answers ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body);
        if (data is List) {
          final list = data
              .map((e) => QuestionnaireAnswer.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
          return {for (final a in list) a.questionId: a};
        }
      } catch (e) {
        print('GET /api/matches/answers parse error: $e');
      }
      return {};
    }

    throw Exception('Failed to fetch answers: ${resp.statusCode} ${resp.body}');
  }

  // GET /api/matches/status (user inferred from token)
  Future<bool> hasUserCompletedQuestionnaire(String userId) async {
    final auth = AuthService();
    final baseUrl = auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/status');

    final token = await auth.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(uri, headers: headers);
    print('GET /api/matches/status ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      final raw = resp.body.trim();
      // Handle plain text boolean
      if (raw.toLowerCase() == 'true') return true;
      if (raw.toLowerCase() == 'false') return false;

      // Try JSON
      try {
        final data = jsonDecode(resp.body);
        if (data is bool) return data;
        if (data is Map<String, dynamic>) {
          if (data['completed'] is bool) return data['completed'] as bool;
          if (data['status'] is String) return (data['status'] as String).toLowerCase() == 'completed';
        }
      } catch (_) {}

      return false;
    }

    throw Exception('Failed to fetch questionnaire status: ${resp.statusCode} ${resp.body}');
  }
}
