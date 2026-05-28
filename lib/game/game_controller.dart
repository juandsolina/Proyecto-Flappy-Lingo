import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/question_repository.dart';
import '../data/session_repository.dart';
import '../models/pipe_model.dart';
import '../models/question_model.dart';
import 'physics_engine.dart';
import 'pipe_manager.dart';

enum GameState { idle, playing, dead }

class TriviafeedBack {
  final bool isCorrect;
  final QuestionModel question;

  const TriviafeedBack({required this.isCorrect, required this.question});
}

class GameController extends ChangeNotifier {
  static const Duration _tickDuration = Duration(milliseconds: 16);
  static const double birdRadius = 18.0;
  static const int maxLives = 3;
  static const int bonusPoints = 3;
  static const int feedbackDuration = 1800;
  static const double _groundHeight = 60.0;

  final PhysicsEngine _physics;
  final PipeManager _pipeManager;
  final QuestionRepository _questions;
  final String selectedCategory;
  final Random _random = Random();

  final List<QuestionModel> _questionPool = [];
  int _questionIndex = 0;

  Timer? _gameTimer;
  Timer? _feedbackTimer;

  double _screenWidth = 0;
  double _screenHeight = 0;

  late double birdX;

  GameState gameState = GameState.idle;
  int score = 0;
  int bestScore = 0;
  int lives = maxLives;
  int correctAnswers = 0;
  int incorrectAnswers = 0;

  Map<String, int> correctByCategory = {};
  Map<String, int> incorrectByCategory = {};

  QuestionModel? currentQuestion;
  TriviafeedBack? triviaFeedback;

  GameController({
    QuestionRepository? repository,
    this.selectedCategory = 'mixed',
  })  : _physics = PhysicsEngine(initialY: 0),
        _pipeManager = PipeManager(),
        _questions = repository ?? QuestionRepository();

  double get birdY => _physics.birdY;
  double get birdTilt => _physics.tiltAngle;
  List<PipeModel> get pipes => _pipeManager.pipes;

  Future<void> init(Size screenSize) async {
    _screenWidth = screenSize.width;
    _screenHeight = screenSize.height;
    birdX = _screenWidth * 0.28;

    _physics.reset(_screenHeight / 2);
    await _prepareQuestionPool();

    _pipeManager.init(
      screenWidth: _screenWidth,
      screenHeight: _screenHeight,
      nextQuestion: _nextQuestion,
    );

    notifyListeners();
  }

  void onTap() {
    switch (gameState) {
      case GameState.idle:
        _startGame();
        break;
      case GameState.playing:
        _physics.flap();
        break;
      case GameState.dead:
        _resetGame();
        break;
    }
  }

  void _startGame() {
    gameState = GameState.playing;
    score = 0;
    lives = maxLives;
    correctAnswers = 0;
    incorrectAnswers = 0;
    correctByCategory = {};
    incorrectByCategory = {};
    currentQuestion = null;
    triviaFeedback = null;

    _physics.reset(_screenHeight / 2);
    _questionIndex = 0;
    _questionPool.shuffle(_random);
    _pipeManager.reset();
    _syncCurrentQuestionWithUpcomingPipe();
    _startTimer();
    notifyListeners();
  }

  void _resetGame() {
    gameState = GameState.idle;
    score = 0;
    lives = maxLives;
    correctAnswers = 0;
    incorrectAnswers = 0;
    correctByCategory = {};
    incorrectByCategory = {};
    currentQuestion = null;
    triviaFeedback = null;

    _physics.reset(_screenHeight / 2);
    _questionIndex = 0;
    _questionPool.shuffle(_random);
    _pipeManager.reset();
    _syncCurrentQuestionWithUpcomingPipe();
    _stopTimers();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_tickDuration, (_) => _onTick());
  }

  void _onTick() {
    if (gameState != GameState.playing) {
      return;
    }

    _physics.update();

    if (_hitVerticalBounds()) {
      _die();
      return;
    }

    final update = _pipeManager.update(birdX, birdY, birdRadius);
    if (update.pointsEarned > 0) {
      score += update.pointsEarned;
    }

    if (update.crossedQuestion != null) {
      currentQuestion = update.crossedQuestion;
    }

    if (update.educationalResult != null && update.crossedQuestion != null) {
      final isCorrect = update.educationalResult!;
      _registerAnswer(update.crossedQuestion!.category, isCorrect);
      if (isCorrect) {
        score += bonusPoints;
      } else {
        lives = (lives - 1).clamp(0, maxLives);
      }

      _showFeedback(isCorrect, update.crossedQuestion!);

      if (lives <= 0) {
        _die();
        return;
      }
    }

    if (_pipeManager.checkCollision(
      birdX: birdX,
      birdY: birdY,
      birdRadius: birdRadius,
    )) {
      _die();
      return;
    }

    _syncCurrentQuestionWithUpcomingPipe();

    notifyListeners();
  }

  void _syncCurrentQuestionWithUpcomingPipe() {
    PipeModel? nextEducational;

    for (final pipe in _pipeManager.pipes) {
      if (!pipe.isEducational || pipe.question == null) {
        continue;
      }

      final isAheadOrAligned = pipe.x + PipeModel.width >= birdX;
      if (!isAheadOrAligned) {
        continue;
      }

      if (nextEducational == null || pipe.x < nextEducational.x) {
        nextEducational = pipe;
      }
    }

    currentQuestion = nextEducational?.question;
  }

  bool _hitVerticalBounds() {
    final top = birdY - birdRadius <= 0;
    final ground = birdY + birdRadius >= (_screenHeight - _groundHeight);
    return top || ground;
  }

  void _showFeedback(bool isCorrect, QuestionModel question) {
    triviaFeedback = TriviafeedBack(isCorrect: isCorrect, question: question);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: feedbackDuration),
      () {
        triviaFeedback = null;
        notifyListeners();
      },
    );
  }

  void _die() {
    if (score > bestScore) {
      bestScore = score;
    }

    unawaited(_saveLocalStats());
    unawaited(_saveProgress());

    gameState = GameState.dead;
    _stopTimers();
    notifyListeners();
  }

  void _registerAnswer(String category, bool isCorrect) {
    if (isCorrect) {
      correctAnswers++;
      correctByCategory[category] = (correctByCategory[category] ?? 0) + 1;
    } else {
      incorrectAnswers++;
      incorrectByCategory[category] = (incorrectByCategory[category] ?? 0) + 1;
    }
  }

  Future<void> _saveProgress() async {
    final session = SessionRepository();
    final token = await session.getToken();
    final user = await session.getUser();
    if (token == null || user == null) return;

    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/progress/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': user.id,
          'score': score,
          'correct': correctAnswers,
          'incorrect': incorrectAnswers,
        }),
      );
    } catch (_) {}
  }

  Future<void> _saveLocalStats() async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in correctByCategory.entries) {
      final key = 'correct_${entry.key}';
      await prefs.setInt(key, (prefs.getInt(key) ?? 0) + entry.value);
    }

    for (final entry in incorrectByCategory.entries) {
      final key = 'incorrect_${entry.key}';
      await prefs.setInt(key, (prefs.getInt(key) ?? 0) + entry.value);
    }
  }

  void _stopTimers() {
    _gameTimer?.cancel();
    _feedbackTimer?.cancel();
    _gameTimer = null;
    _feedbackTimer = null;
  }

  Future<void> _prepareQuestionPool() async {
    _questionPool.clear();

    try {
      final fromRepository = await _questions.preload(
        count: 16,
        category: selectedCategory,
      );
      _questionPool.addAll(fromRepository);
    } catch (_) {
      // Si falla el backend/repositorio, usa el fallback local.
    }

    if (_questionPool.isEmpty) {
      _questionPool.addAll(_localFallbackQuestions);
    }

    _questionPool.shuffle(_random);
    _questionIndex = 0;
  }

  static const List<QuestionModel> _localFallbackQuestions = [
    QuestionModel(
      wordInSpanish: 'Perro',
      correctAnswer: 'Dog',
      wrongAnswer: 'Cat',
      category: 'animals',
    ),
    QuestionModel(
      wordInSpanish: 'Gato',
      correctAnswer: 'Cat',
      wrongAnswer: 'Dog',
      category: 'animals',
    ),
    QuestionModel(
      wordInSpanish: 'Correr',
      correctAnswer: 'To run',
      wrongAnswer: 'To walk',
      category: 'verbs',
    ),
    QuestionModel(
      wordInSpanish: 'Comer',
      correctAnswer: 'To eat',
      wrongAnswer: 'To drink',
      category: 'verbs',
    ),
    QuestionModel(
      wordInSpanish: 'Rojo',
      correctAnswer: 'Red',
      wrongAnswer: 'Blue',
      category: 'colors',
    ),
    QuestionModel(
      wordInSpanish: 'Azul',
      correctAnswer: 'Blue',
      wrongAnswer: 'Green',
      category: 'colors',
    ),
    QuestionModel(
      wordInSpanish: 'Pan',
      correctAnswer: 'Bread',
      wrongAnswer: 'Cake',
      category: 'food',
    ),
    QuestionModel(
      wordInSpanish: 'Leche',
      correctAnswer: 'Milk',
      wrongAnswer: 'Water',
      category: 'food',
    ),
  ];

  QuestionModel _nextQuestion() {
    if (_questionPool.isEmpty) {
      return const QuestionModel(
        wordInSpanish: 'Hola',
        correctAnswer: 'Hello',
        wrongAnswer: 'Bye',
        category: 'phrases',
      );
    }

    final question = _questionPool[_questionIndex % _questionPool.length];
    _questionIndex++;
    return question;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
