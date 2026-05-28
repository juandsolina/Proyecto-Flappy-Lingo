// models/question_model.dart
// Representa una pregunta educativa con su respuesta correcta y un distractor.
// Diseñado para ser compatible con la respuesta JSON de la API Gemini.

class QuestionModel {
  /// Palabra o frase en español que se muestra en pantalla.
  final String wordInSpanish;

  /// Traducción correcta al inglés (irá en uno de los tubos).
  final String correctAnswer;

  /// Opción incorrecta / distractor (irá en el otro tubo).
  final String wrongAnswer;

  /// Categoría de la pregunta (vocabulario, gramática, frases, etc.)
  final String category;

  const QuestionModel({
    required this.wordInSpanish,
    required this.correctAnswer,
    required this.wrongAnswer,
    required this.category,
  });

  // ── Serialización JSON (compatible con respuesta de Gemini API) ──────────
  // Ejemplo de JSON esperado del backend:
  // {
  //   "word_in_spanish": "Perro",
  //   "correct_answer": "Dog",
  //   "wrong_answer": "Cat",
  //   "category": "vocabulary"
  // }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      wordInSpanish: json['word_in_spanish'] as String,
      correctAnswer: json['correct_answer'] as String,
      wrongAnswer: json['wrong_answer'] as String,
      category: json['category'] as String? ?? 'vocabulary',
    );
  }

  Map<String, dynamic> toJson() => {
        'word_in_spanish': wordInSpanish,
        'correct_answer': correctAnswer,
        'wrong_answer': wrongAnswer,
        'category': category,
      };
}
