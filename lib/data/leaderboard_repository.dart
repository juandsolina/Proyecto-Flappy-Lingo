import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class LeaderboardEntry {
  final String name;
  final int score;

  LeaderboardEntry({required this.name, required this.score});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] as String,
      score: json['score'] as int,
    );
  }
}

class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/api/leaderboard?limit=$limit',
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        return data
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LeaderboardRepository] Error: $e');
      }
      return [];
    }
  }
}
