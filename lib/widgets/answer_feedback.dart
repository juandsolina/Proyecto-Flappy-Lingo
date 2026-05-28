import 'package:flutter/material.dart';

class AnswerFeedback extends StatefulWidget {
  final bool? isCorrect; // null = sin feedback activo
  const AnswerFeedback({super.key, this.isCorrect});

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnswerFeedback old) {
    super.didUpdateWidget(old);
    if (widget.isCorrect != null && widget.isCorrect != old.isCorrect) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCorrect == null) return const SizedBox.shrink();

    final color = widget.isCorrect! ? Colors.green : Colors.red;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => IgnorePointer(
        child: Container(
          color: color.withValues(alpha: _opacity.value),
          child: Center(
            child: Opacity(
              opacity: _opacity.value * 2.2 > 1 ? 1 : _opacity.value * 2.2,
              child: Text(
                widget.isCorrect! ? '✅ ¡Correcto!' : '❌ Incorrecto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
