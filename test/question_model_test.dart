// test/models/question_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/models/question_model.dart';

void main() {
  group('QuestionModel', () {
    const validJson = {
      'word_in_spanish': 'Correr',
      'correct_answer': 'To run',
      'wrong_answer': 'To walk',
      'category': 'verbs',
    };

    test('fromJson() construye el modelo correctamente', () {
      final model = QuestionModel.fromJson(validJson);
      expect(model.wordInSpanish, 'Correr');
      expect(model.correctAnswer, 'To run');
      expect(model.wrongAnswer, 'To walk');
      expect(model.category, 'verbs');
    });

    test('fromJson() usa "vocabulary" como categoría por defecto si falta', () {
      final json = Map<String, dynamic>.from(validJson)..remove('category');
      final model = QuestionModel.fromJson(json);
      expect(model.category, 'vocabulary');
    });

    test('toJson() serializa todos los campos correctamente', () {
      const model = QuestionModel(
        wordInSpanish: 'Perro',
        correctAnswer: 'Dog',
        wrongAnswer: 'Cat',
        category: 'animals',
      );
      final json = model.toJson();
      expect(json['word_in_spanish'], 'Perro');
      expect(json['correct_answer'], 'Dog');
      expect(json['wrong_answer'], 'Cat');
      expect(json['category'], 'animals');
    });

    test('fromJson() → toJson() es reversible (round-trip)', () {
      final model = QuestionModel.fromJson(validJson);
      final json = model.toJson();
      final model2 = QuestionModel.fromJson(json);
      expect(model2.wordInSpanish, model.wordInSpanish);
      expect(model2.correctAnswer, model.correctAnswer);
      expect(model2.wrongAnswer, model.wrongAnswer);
      expect(model2.category, model.category);
    });
  });
}
