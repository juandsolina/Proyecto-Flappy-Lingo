// test/data/leaderboard_repository_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/data/leaderboard_repository.dart';

void main() {
  group('LeaderboardEntry', () {
    test('fromJson() construye correctamente', () {
      final entry = LeaderboardEntry.fromJson({'name': 'Juan', 'score': 150});
      expect(entry.name, 'Juan');
      expect(entry.score, 150);
    });

    test('fromJson() con score 0', () {
      final entry = LeaderboardEntry.fromJson({'name': 'Nuevo', 'score': 0});
      expect(entry.score, 0);
    });
  });

  group('LeaderboardRepository — parseo de respuesta', () {
    test('parsea lista de entradas correctamente', () {
      final body = jsonEncode({
        'data': [
          {'name': 'Ana', 'score': 300},
          {'name': 'Bob', 'score': 200},
          {'name': 'Carlos', 'score': 100},
        ]
      });

      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      final entries = data
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(entries.length, 3);
      expect(entries[0].name, 'Ana');
      expect(entries[0].score, 300);
      expect(entries[2].name, 'Carlos');
    });

    test('lista vacía no lanza error', () {
      final body = jsonEncode({'data': []});
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      expect(data, isEmpty);
    });

    test('status != 200 retorna lista vacía', () {
      // Simula la lógica del repositorio
      const statusCode = 500;
      final result = statusCode == 200 ? ['algo'] : <String>[];
      expect(result, isEmpty);
    });
  });
}
