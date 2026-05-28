import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int correct;
  final int incorrect;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.correct,
    required this.incorrect,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💀 Game Over',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('Puntaje: $score',
                style: const TextStyle(color: Colors.yellow, fontSize: 24)),
            const SizedBox(height: 8),
            Text('✅ Correctas: $correct   ❌ Incorrectas: $incorrect',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: onRestart, child: const Text('🔄 Reintentar')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onMenu,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('🏠 Menú'),
            ),
          ],
        ),
      ),
    );
  }
}
