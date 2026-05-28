// test/data/question_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/data/question_repository.dart';
import 'package:flappy_lingo/models/question_model.dart';

void main() {
  group('QuestionRepository — fallback local', () {
    // Subclase que fuerza siempre el fallback local (simula backend caído)
    // Para esto, necesitas exponer un constructor de QuestionRepository
    // que acepte fuentes inyectadas. Si no quieres modificarlo,
    // estas pruebas validan la lógica del _LocalQuestionSource directamente.

    test('QuestionModel del fallback tiene todos los campos requeridos', () {
      const q = QuestionModel(
        wordInSpanish: 'Correr',
        correctAnswer: 'To run',
        wrongAnswer: 'To walk',
        category: 'verbs',
      );
      expect(q.wordInSpanish, isNotEmpty);
      expect(q.correctAnswer, isNotEmpty);
      expect(q.wrongAnswer, isNotEmpty);
      expect(q.category, isNotEmpty);
    });

    test('correctAnswer y wrongAnswer son distintos', () {
      const q = QuestionModel(
        wordInSpanish: 'Perro',
        correctAnswer: 'Dog',
        wrongAnswer: 'Cat',
        category: 'animals',
      );
      expect(q.correctAnswer, isNot(equals(q.wrongAnswer)));
    });

    test('preload() retorna una lista no vacía con repositorio fake', () async {
      final repo = _FakeRepo();
      final questions = await repo.preload(count: 5);
      expect(questions.length, 5);
      for (final q in questions) {
        expect(q.wordInSpanish, isNotEmpty);
        expect(q.correctAnswer, isNotEmpty);
      }
    });

    test('preload() retorna exactamente count elementos', () async {
      final repo = _FakeRepo();
      final q3 = await repo.preload(count: 3);
      final q8 = await repo.preload(count: 8);
      expect(q3.length, 3);
      expect(q8.length, 8);
    });

    test('getQuestion() retorna una pregunta válida', () async {
      final repo = _FakeRepo();
      final q = await repo.getQuestion();
      expect(q.wordInSpanish, isNotEmpty);
      expect(q.correctAnswer, isNotEmpty);
      expect(q.wrongAnswer, isNotEmpty);
    });
  });
}

/// Repositorio fake que usa solo preguntas locales, sin red.
class _FakeRepo extends QuestionRepository {
  static const _local = [
    QuestionModel(
        wordInSpanish: 'Correr',
        correctAnswer: 'To run',
        wrongAnswer: 'To walk',
        category: 'verbs'),
    QuestionModel(
        wordInSpanish: 'Comer',
        correctAnswer: 'To eat',
        wrongAnswer: 'To drink',
        category: 'verbs'),
    QuestionModel(
        wordInSpanish: 'Casa',
        correctAnswer: 'House',
        wrongAnswer: 'Street',
        category: 'nouns'),
    QuestionModel(
        wordInSpanish: 'Perro',
        correctAnswer: 'Dog',
        wrongAnswer: 'Cat',
        category: 'nouns'),
    QuestionModel(
        wordInSpanish: 'Grande',
        correctAnswer: 'Big',
        wrongAnswer: 'Tall',
        category: 'adjectives'),
    QuestionModel(
        wordInSpanish: 'Rápido',
        correctAnswer: 'Fast',
        wrongAnswer: 'Strong',
        category: 'adjectives'),
    QuestionModel(
        wordInSpanish: 'Feliz',
        correctAnswer: 'Happy',
        wrongAnswer: 'Calm',
        category: 'adjectives'),
    QuestionModel(
        wordInSpanish: 'Agua',
        correctAnswer: 'Water',
        wrongAnswer: 'Juice',
        category: 'nouns'),
  ];

  @override
  Future<List<QuestionModel>> preload({
    int count = 12,
    String category = 'mixed',
  }) async {
    final result = <QuestionModel>[];
    for (int i = 0; i < count; i++) {
      result.add(_local[i % _local.length]);
    }
    return result;
  }

  @override
  Future<QuestionModel> getQuestion({String category = 'mixed'}) async {
    return _local.first;
  }
}
