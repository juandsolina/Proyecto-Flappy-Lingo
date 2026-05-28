import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/question_model.dart';

abstract class QuestionSource {
  Future<QuestionModel> fetchQuestion({String category});
}

class _GeminiQuestionSource implements QuestionSource {
  @override
  Future<QuestionModel> fetchQuestion({String category = 'mixed'}) async {
    final uri = Uri.parse(
      '${AppConfig.questionEndpoint}?category=$category',
    );

    final response = await http.get(uri).timeout(
          const Duration(seconds: 8),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return QuestionModel.fromJson(json);
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
}

class _LocalQuestionSource implements QuestionSource {
  static const List<Map<String, String>> _questions = [
    {
      "word_in_spanish": "Correr",
      "correct_answer": "To run",
      "wrong_answer": "To walk",
      "category": "verbs"
    },
    {
      "word_in_spanish": "Comer",
      "correct_answer": "To eat",
      "wrong_answer": "To drink",
      "category": "verbs"
    },
    {
      "word_in_spanish": "Dormir",
      "correct_answer": "To sleep",
      "wrong_answer": "To rest",
      "category": "verbs"
    },
    {
      "word_in_spanish": "Hablar",
      "correct_answer": "To speak",
      "wrong_answer": "To listen",
      "category": "verbs"
    },
    {
      "word_in_spanish": "Escribir",
      "correct_answer": "To write",
      "wrong_answer": "To read",
      "category": "verbs"
    },
    {
      "word_in_spanish": "Perro",
      "correct_answer": "Dog",
      "wrong_answer": "Cat",
      "category": "animals"
    },
    {
      "word_in_spanish": "Gato",
      "correct_answer": "Cat",
      "wrong_answer": "Dog",
      "category": "animals"
    },
    {
      "word_in_spanish": "León",
      "correct_answer": "Lion",
      "wrong_answer": "Tiger",
      "category": "animals"
    },
    {
      "word_in_spanish": "Avión",
      "correct_answer": "Plane",
      "wrong_answer": "Train",
      "category": "travel"
    },
    {
      "word_in_spanish": "Hotel",
      "correct_answer": "Hotel",
      "wrong_answer": "Hospital",
      "category": "travel"
    },
    {
      "word_in_spanish": "Pasaporte",
      "correct_answer": "Passport",
      "wrong_answer": "Ticket",
      "category": "travel"
    },
    {
      "word_in_spanish": "Pan",
      "correct_answer": "Bread",
      "wrong_answer": "Rice",
      "category": "food"
    },
    {
      "word_in_spanish": "Queso",
      "correct_answer": "Cheese",
      "wrong_answer": "Butter",
      "category": "food"
    },
    {
      "word_in_spanish": "Sopa",
      "correct_answer": "Soup",
      "wrong_answer": "Salad",
      "category": "food"
    },
  ];

  static String _normalizeCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'verbos':
        return 'verbs';
      case 'animales':
        return 'animals';
      case 'viajes':
      case 'viaje':
        return 'travel';
      case 'comida':
      case 'alimentos':
        return 'food';
      default:
        return category.trim().toLowerCase();
    }
  }

  @override
  Future<QuestionModel> fetchQuestion({String category = 'mixed'}) async {
    final normalized = _normalizeCategory(category);
    final filtered = normalized == 'mixed'
        ? _questions
        : _questions.where((q) => q['category'] == normalized).toList();

    final source = filtered.isEmpty ? _questions : filtered;
    final map = Map<String, dynamic>.from(
      source[Random().nextInt(source.length)],
    );
    return QuestionModel.fromJson(map);
  }
}

class QuestionRepository {
  final QuestionSource _primary = _GeminiQuestionSource();
  final QuestionSource _fallback = _LocalQuestionSource();

  static String _questionKey(QuestionModel question) {
    return '${question.category.trim().toLowerCase()}|'
        '${question.wordInSpanish.trim().toLowerCase()}';
  }

  static String _normalizeCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'verbos':
        return 'verbs';
      case 'animales':
        return 'animals';
      case 'viajes':
      case 'viaje':
        return 'travel';
      case 'comida':
      case 'alimentos':
        return 'food';
      default:
        return category.trim().toLowerCase();
    }
  }

  bool get _isPlaceholderConfig =>
      AppConfig.baseUrl.contains('NOMBRE_DE_TU_LAPTOP');

  Future<List<QuestionModel>> preload({
    int count = 12,
    String category = 'mixed',
  }) async {
    final normalized = _normalizeCategory(category);
    final initialBatch = await Future.wait(
      List.generate(count, (_) => getQuestion(category: normalized)),
    );

    final uniqueByWord = <String, QuestionModel>{};
    for (final question in initialBatch) {
      uniqueByWord.putIfAbsent(_questionKey(question), () => question);
    }

    int attempts = 0;
    final maxAttempts = count * 2;
    while (uniqueByWord.length < count && attempts < maxAttempts) {
      final missing = count - uniqueByWord.length;
      final batchSize = missing > 4 ? 4 : missing;
      final extraBatch = await Future.wait(
        List.generate(batchSize, (_) => getQuestion(category: normalized)),
      );

      for (final question in extraBatch) {
        uniqueByWord.putIfAbsent(_questionKey(question), () => question);
      }
      attempts++;
    }

    final result = uniqueByWord.values.take(count).toList();

    while (result.length < count) {
      result.add(await getQuestion(category: normalized));
    }

    return result;
  }

  Future<QuestionModel> getQuestion({String category = 'mixed'}) async {
    final normalized = _normalizeCategory(category);
    if (_isPlaceholderConfig) {
      return _fallback.fetchQuestion(category: normalized);
    }

    try {
      return await _primary.fetchQuestion(category: normalized);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[QuestionRepository] Backend no disponible, usando local: $e');
      }
      return await _fallback.fetchQuestion(category: normalized);
    }
  }
}
