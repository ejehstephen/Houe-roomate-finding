import 'dart:convert';

import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:http/http.dart' as http;

class MatchingService {
  final AuthService _auth = AuthService();

  // GET /api/matches
  Future<List<RoommateMatchModel>> getMatches() async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('No authentication token found');

    final baseUrl = _auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches');

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('GET /api/matches ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = data is List
          ? data
          : (data is Map<String, dynamic> && data['matches'] is List
              ? data['matches']
              : []);

      return list
          .map<RoommateMatchModel>((e) =>
              RoommateMatchModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    throw Exception('Failed to load matches: ${resp.statusCode} ${resp.body}');
  }

  // POST /api/matches/recalculate
  Future<void> calculateMatches(String userId) async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('No authentication token found');

    final baseUrl = _auth.baseUrl;
    final uri = Uri.parse('$baseUrl/api/matches/recalculate');

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('POST /api/matches/recalculate ${resp.statusCode}: ${resp.body}');
    if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) {
      return;
    }

    throw Exception('Failed to recalculate matches: ${resp.statusCode} ${resp.body}');
  }
}
