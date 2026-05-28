// game/game_screen.dart
// Versión 2: HUD con vidas, palabra en español flotante y feedback de trivia.

import 'package:flutter/material.dart';
import 'game_controller.dart';
// ...existing code...
import '../screens/game_over_screen.dart';
import '../screens/menu_screen.dart';
import '../widgets/bird_widget.dart';
import '../widgets/pipe_widget.dart';

class GameScreen extends StatefulWidget {
  final String selectedCategory;

  const GameScreen({
    super.key,
    this.selectedCategory = 'mixed',
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  bool _initialized = false;
  bool _loading = true; // ← nuevo
  bool _navigatedToGameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(selectedCategory: widget.selectedCategory);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller.init(MediaQuery.of(context).size).then((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ── Pantalla de carga mientras preload() termina ──────────
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF87CEEB),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐦', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Cargando preguntas...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _controller.onTap,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            _maybeNavigateToGameOver(context);

            return Stack(
              children: [
                _Background(screenSize: size),
                _Ground(screenSize: size),
                ..._controller.pipes.map(
                  (p) => PipeWidget(
                    pipe: p,
                    screenHeight: size.height,
                  ),
                ),
                BirdWidget(
                  x: _controller.birdX,
                  y: _controller.birdY,
                  radius: GameController.birdRadius,
                  tiltAngle: _controller.birdTilt,
                ),
                if (_controller.gameState == GameState.playing &&
                    _controller.currentQuestion != null)
                  _WordBanner(word: _controller.currentQuestion!.wordInSpanish),
                _HUD(
                  score: _controller.score,
                  bestScore: _controller.bestScore,
                  lives: _controller.lives,
                  maxLives: GameController.maxLives,
                ),
                if (_controller.triviaFeedback != null)
                  _TriviaFeedback(feedback: _controller.triviaFeedback!),
                if (_controller.gameState == GameState.idle)
                  const _IdleOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _maybeNavigateToGameOver(BuildContext context) {
    if (_controller.gameState == GameState.dead) {
      if (_navigatedToGameOver) return;
      _navigatedToGameOver = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (gameOverContext) => GameOverScreen(
              score: _controller.score,
              correct: _controller.correctAnswers,
              incorrect: _controller.incorrectAnswers,
              onRestart: () => Navigator.pushReplacement(
                gameOverContext,
                MaterialPageRoute(
                  builder: (_) =>
                      GameScreen(selectedCategory: widget.selectedCategory),
                ),
              ),
              onMenu: () => Navigator.pushAndRemoveUntil(
                gameOverContext,
                MaterialPageRoute(builder: (_) => const MenuScreen()),
                (_) => false,
              ),
            ),
          ),
        );
      });
      return;
    }

    _navigatedToGameOver = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets del HUD y overlays
// ─────────────────────────────────────────────────────────────────────────────

/// Banner que muestra la palabra en español a traducir.
class _WordBanner extends StatelessWidget {
  final String word;
  const _WordBanner({required this.word});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 52,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇪🇸 ', style: TextStyle(fontSize: 18)),
              Text(
                word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feedback visual tras cruzar un tubo educativo.
class _TriviaFeedback extends StatelessWidget {
  final TriviafeedBack feedback;
  const _TriviaFeedback({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback.isCorrect;
    return Positioned(
      bottom: 120,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isCorrect ? const Color(0xFF81C784) : const Color(0xFFEF9A9A),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? '✅ ¡Correcto! +${GameController.bonusPoints} pts'
                  : '❌ Incorrecto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 6),
              Text(
                '${feedback.question.wordInSpanish} = ${feedback.question.correctAnswer}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HUD extends StatelessWidget {
  final int score;
  final int bestScore;
  final int lives;
  final int maxLives;

  const _HUD({
    required this.score,
    required this.bestScore,
    required this.lives,
    required this.maxLives,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 48,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Score
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
          Text(
            'Mejor: $bestScore',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          // Vidas
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              maxLives,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  i < lives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final Size screenSize;
  const _Background({required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB0E0FF)],
        ),
      ),
      child: CustomPaint(painter: _CloudPainter()),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void cloud(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r, p);
      canvas.drawCircle(Offset(cx + r * 0.9, cy + r * 0.15), r * 0.75, p);
      canvas.drawCircle(Offset(cx - r * 0.75, cy + r * 0.2), r * 0.65, p);
    }

    cloud(size.width * 0.15, size.height * 0.12, 28);
    cloud(size.width * 0.55, size.height * 0.08, 22);
    cloud(size.width * 0.82, size.height * 0.18, 26);
    cloud(size.width * 0.35, size.height * 0.22, 18);
  }

  @override
  bool shouldRepaint(_CloudPainter _) => false;
}

class _Ground extends StatelessWidget {
  final Size screenSize;
  const _Ground({required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        width: screenSize.width,
        height: 60,
        color: const Color(0xFF8B6914),
        child: Container(height: 12, color: const Color(0xFF5D8A3C)),
      ),
    );
  }
}

class _IdleOverlay extends StatelessWidget {
  const _IdleOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🐦 Flappy Lingo',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            SizedBox(height: 6),
            Text(
              'Pasa por la traducción correcta',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            SizedBox(height: 10),
            Text(
              'Toca para comenzar',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
