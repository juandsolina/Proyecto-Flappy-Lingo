class CustomVocabularyItem {
  final int id;
  final String userId;
  final String wordInSpanish;
  final String correctAnswer;
  final String wrongAnswer;
  final String category;
  final String createdAt;
  final String updatedAt;

  const CustomVocabularyItem({
    required this.id,
    required this.userId,
    required this.wordInSpanish,
    required this.correctAnswer,
    required this.wrongAnswer,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomVocabularyItem.fromJson(Map<String, dynamic> json) {
    return CustomVocabularyItem(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      wordInSpanish: json['word_in_spanish'] as String,
      correctAnswer: json['correct_answer'] as String,
      wrongAnswer: json['wrong_answer'] as String,
      category: json['category'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
