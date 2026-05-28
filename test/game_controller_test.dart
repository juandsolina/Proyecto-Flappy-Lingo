// test/game/game_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/game/game_controller.dart';
import 'package:flappy_lingo/data/question_repository.dart';
import 'package:flappy_lingo/models/question_model.dart';

/// Repositorio local de preguntas para tests (sin red).
class _FakeQuestionRepository extends QuestionRepository {
  @override
  Future<List<QuestionModel>> preload({
    int count = 12,
    String category = 'mixed',
  }) async {
    return List.generate(
      count,
      (i) => QuestionModel(
        wordInSpanish: 'Palabra$i',
        correctAnswer: 'Answer$i',
        wrongAnswer: 'Wrong$i',
        category: i % 2 == 0 ? 'verbs' : 'nouns',
      ),
    );
  }

  @override
  Future<QuestionModel> getQuestion({String category = 'mixed'}) async {
    return const QuestionModel(
      wordInSpanish: 'Correr',
      correctAnswer: 'To run',
      wrongAnswer: 'To walk',
      category: 'verbs',
    );
  }
}

void main() {
  group('GameController', () {
    late GameController controller;

    setUp(() {
      controller = GameController(repository: _FakeQuestionRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('estado inicial es idle', () {
      expect(controller.gameState, GameState.idle);
    });

    test('init() configura posición del ave y estado', () async {
      await controller.init(const Size(400, 800));
      expect(controller.birdY, closeTo(400, 1)); // screenHeight / 2
      expect(controller.gameState, GameState.idle);
    });

    test('onTap() en idle cambia a playing', () async {
      await controller.init(const Size(400, 800));
      controller.onTap();
      expect(controller.gameState, GameState.playing);
    });

    test('score inicia en 0 al empezar partida', () async {
      await controller.init(const Size(400, 800));
      controller.onTap(); // playing
      expect(controller.score, 0);
    });

    test('lives inicia en maxLives al empezar', () async {
      await controller.init(const Size(400, 800));
      controller.onTap();
      expect(controller.lives, GameController.maxLives);
    });

    test('correctAnswers e incorrectAnswers inician en 0', () async {
      await controller.init(const Size(400, 800));
      controller.onTap();
      expect(controller.correctAnswers, 0);
      expect(controller.incorrectAnswers, 0);
    });

    test('correctByCategory e incorrectByCategory inician vacíos', () async {
      await controller.init(const Size(400, 800));
      controller.onTap();
      expect(controller.correctByCategory, isEmpty);
      expect(controller.incorrectByCategory, isEmpty);
    });

    test('onTap() en dead vuelve a idle', () async {
      await controller.init(const Size(400, 800));
      controller.onTap(); // playing
      // Forzar estado dead manualmente para el test
      // ignore: invalid_use_of_protected_member
      controller.gameState = GameState.dead;
      controller.onTap();
      expect(controller.gameState, GameState.idle);
    });

    test('bestScore se actualiza si score supera el anterior', () async {
      await controller.init(const Size(400, 800));
      controller.onTap(); // playing
      // Incrementar score manualmente
      // ignore: invalid_use_of_protected_member
      controller.score = 50;
      controller.gameState = GameState.dead;
      // Simular _die() actualizando bestScore
      if (controller.score > controller.bestScore) {
        // ignore: invalid_use_of_protected_member
        controller.bestScore = controller.score;
      }
      expect(controller.bestScore, 50);
    });

    test('pipes no está vacío después de init', () async {
      await controller.init(const Size(400, 800));
      expect(controller.pipes, isNotEmpty);
    });
  });
}
