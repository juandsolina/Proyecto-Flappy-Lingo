// game/pipe_manager.dart
// Genera, mueve y recicla los pares de tubos.
// Versión 2: cada 3er tubo es educativo (lleva una pregunta).

import 'dart:math';
import '../models/pipe_model.dart';
import '../models/question_model.dart';

// Resultado del update: puntos normales + si el ave cruzó un tubo educativo.
class PipeUpdateResult {
  final int pointsEarned;

  /// null = no cruzó tubo educativo. true = pasó por correcto. false = incorrecto.
  final bool? educationalResult;

  /// La pregunta del tubo educativo cruzado (para mostrar feedback en UI).
  final QuestionModel? crossedQuestion;

  const PipeUpdateResult({
    this.pointsEarned = 0,
    this.educationalResult,
    this.crossedQuestion,
  });
}

class PipeManager {
  // ── Constantes ────────────────────────────────────────────────────────────
  static const double pipeSpeed = 2.0;
  static const double pipeSpacing = 420.0;
  static const double gapMargin = 130.0;
  static const double _minHoleHeight = 140.0;
  static const double _maxHoleHeight = 185.0;
  static const double _minHoleSeparation = 80.0;

  /// Cada cuántos tubos aparece uno educativo.
  static const int educationalEvery = 3;

  // ── Estado ────────────────────────────────────────────────────────────────
  final List<PipeModel> _pipes = [];
  final Random _random = Random();

  double _screenWidth = 0;
  double _screenHeight = 0;
  int _pipeCount = 0; // contador global para saber cuándo poner educativo

  // Fuente de preguntas inyectada desde el controller.
  QuestionModel Function()? _nextQuestion;

  // ── Inicialización ────────────────────────────────────────────────────────

  void init({
    required double screenWidth,
    required double screenHeight,
    required QuestionModel Function() nextQuestion,
  }) {
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    _nextQuestion = nextQuestion;
    _pipes.clear();
    _pipeCount = 0;

    for (int i = 0; i < 3; i++) {
      _pipes.add(_buildPipe(_screenWidth + 100 + i * pipeSpacing));
    }
  }

  // ── API pública ───────────────────────────────────────────────────────────

  List<PipeModel> get pipes => List.unmodifiable(_pipes);

  /// Avanza un tick. Devuelve PipeUpdateResult con puntos y resultado educativo.
  PipeUpdateResult update(double birdX, double birdY, double birdRadius) {
    int pointsEarned = 0;
    bool? educationalResult;
    QuestionModel? crossedQuestion;

    for (final pipe in _pipes) {
      pipe.x -= pipeSpeed;

      // ── El ave acaba de cruzar el borde derecho del tubo ──────────────────
      if (!pipe.scored && birdX > pipe.x + PipeModel.width) {
        pipe.scored = true;
        pointsEarned++;

        // Si es educativo y aún no fue evaluado → determina si pasó correcto.
        if (pipe.isEducational && !pipe.evaluated) {
          pipe.evaluated = true;
          crossedQuestion = pipe.question;
          final passedTop = _didPassUpperAnswerHole(pipe, birdY, birdRadius);
          educationalResult = (passedTop == pipe.correctIsTop);
        }
      }
    }

    _recyclePipes();
    return PipeUpdateResult(
      pointsEarned: pointsEarned,
      educationalResult: educationalResult,
      crossedQuestion: crossedQuestion,
    );
  }

  void reset() {
    _pipes.clear();
    _pipeCount = 0;
    for (int i = 0; i < 3; i++) {
      _pipes.add(_buildPipe(_screenWidth + 100 + i * pipeSpacing));
    }
  }

  // ── Colisión ──────────────────────────────────────────────────────────────

  bool checkCollision({
    required double birdX,
    required double birdY,
    required double birdRadius,
  }) {
    for (final pipe in _pipes) {
      final pipeLeft = pipe.x;
      final pipeRight = pipe.x + PipeModel.width;
      final r = birdRadius * 0.8;

      if (birdX + r > pipeLeft && birdX - r < pipeRight) {
        if (pipe.hasAnswerHoles) {
          final holeHalf = pipe.answerHoleHeight! / 2;
          final upperTop = pipe.upperHoleCenterY! - holeHalf;
          final upperBottom = pipe.upperHoleCenterY! + holeHalf;
          final lowerTop = pipe.lowerHoleCenterY! - holeHalf;
          final lowerBottom = pipe.lowerHoleCenterY! + holeHalf;

          final inUpperHole = birdY - r >= upperTop && birdY + r <= upperBottom;
          final inLowerHole = birdY - r >= lowerTop && birdY + r <= lowerBottom;

          if (!inUpperHole && !inLowerHole) {
            return true;
          }
          continue;
        }

        final gapTop = pipe.gapCenterY - pipe.gapHeight / 2;
        final gapBottom = pipe.gapCenterY + pipe.gapHeight / 2;

        if (birdY - r < gapTop || birdY + r > gapBottom) {
          return true;
        }
      }
    }
    return false;
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  PipeModel _buildPipe(double x) {
    _pipeCount++;

    final gapCenter =
        gapMargin + _random.nextDouble() * (_screenHeight - gapMargin * 2);

    // Cada 3er tubo es educativo.
    final isEducational = (_pipeCount % educationalEvery == 0);
    final question = isEducational ? _nextQuestion?.call() : null;
    final correctIsTop = _random.nextBool();

    double? upperHoleCenterY;
    double? lowerHoleCenterY;
    double? answerHoleHeight;

    if (isEducational) {
      answerHoleHeight = _minHoleHeight +
          _random.nextDouble() * (_maxHoleHeight - _minHoleHeight);

      final availableRange = (_screenHeight - gapMargin * 2) -
          (answerHoleHeight * 2) -
          _minHoleSeparation;

      if (availableRange > 0) {
        final topStart = gapMargin +
            answerHoleHeight / 2 +
            _random.nextDouble() * availableRange;
        final bottomStart = topStart +
            answerHoleHeight +
            _minHoleSeparation +
            _random.nextDouble() * 30;

        upperHoleCenterY = topStart;
        lowerHoleCenterY = bottomStart.clamp(
          gapMargin + answerHoleHeight / 2,
          _screenHeight - gapMargin - answerHoleHeight / 2,
        );
      } else {
        upperHoleCenterY = _screenHeight * 0.35;
        lowerHoleCenterY = _screenHeight * 0.65;
      }
    }

    return PipeModel(
      x: x,
      gapCenterY: gapCenter,
      question: question,
      correctIsTop: correctIsTop,
      upperHoleCenterY: upperHoleCenterY,
      lowerHoleCenterY: lowerHoleCenterY,
      answerHoleHeight: answerHoleHeight,
    );
  }

  bool _didPassUpperAnswerHole(
      PipeModel pipe, double birdY, double birdRadius) {
    if (!pipe.hasAnswerHoles) {
      return birdY < pipe.gapCenterY;
    }

    final safeRadius = birdRadius * 0.6;
    final holeHalf = pipe.answerHoleHeight! / 2;
    final upperTop = pipe.upperHoleCenterY! - holeHalf;
    final upperBottom = pipe.upperHoleCenterY! + holeHalf;
    final lowerTop = pipe.lowerHoleCenterY! - holeHalf;
    final lowerBottom = pipe.lowerHoleCenterY! + holeHalf;

    final inUpperHole =
        birdY - safeRadius >= upperTop && birdY + safeRadius <= upperBottom;
    final inLowerHole =
        birdY - safeRadius >= lowerTop && birdY + safeRadius <= lowerBottom;

    if (inUpperHole && !inLowerHole) {
      return true;
    }
    if (inLowerHole && !inUpperHole) {
      return false;
    }

    final upperDist = (birdY - pipe.upperHoleCenterY!).abs();
    final lowerDist = (birdY - pipe.lowerHoleCenterY!).abs();
    return upperDist <= lowerDist;
  }

  void _recyclePipes() {
    for (int i = 0; i < _pipes.length; i++) {
      if (_pipes[i].x + PipeModel.width < 0) {
        final maxX = _pipes.fold<double>(
          0,
          (prev, p) => p.x > prev ? p.x : prev,
        );
        _pipes[i] = _buildPipe(maxX + pipeSpacing);
      }
    }
  }
}
