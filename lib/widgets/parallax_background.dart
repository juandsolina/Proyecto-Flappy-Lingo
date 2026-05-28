import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({super.key});

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _cloudOffset = 0;
  double _groundOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() {
        setState(() {
          _cloudOffset = (_cloudOffset - 0.5) % 400;
          _groundOffset = (_groundOffset - 2) % 60;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Cielo degradado
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF87CEEB), Color(0xFFB0E0FF)],
            ),
          ),
        ),

        // Nubes (capa lenta)
        for (final cloud in _clouds(size))
          Positioned(
            left: ((cloud['x'] as double) + _cloudOffset) % (size.width + 100) -
                100,
            top: cloud['y'] as double,
            child: _Cloud(width: cloud['w'] as double),
          ),

        // Suelo (capa rápida)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: CustomPaint(
              size: Size(size.width, 50),
              painter: _GroundPainter(_groundOffset),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, double>> _clouds(Size size) => [
        {'x': 50, 'y': 60, 'w': 90},
        {'x': 200, 'y': 30, 'w': 70},
        {'x': 320, 'y': 80, 'w': 110},
        {'x': 500, 'y': 45, 'w': 80},
      ];
}

class _Cloud extends StatelessWidget {
  final double width;
  const _Cloud({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)
        ],
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  final double offset;
  _GroundPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(0, 20, size.width, size.height), paint);

    final grass = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(Rect.fromLTWH(0, 12, size.width, 12), grass);

    // Líneas de detalle animadas
    final line = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 3;
    for (double x = -60 + offset; x < size.width + 60; x += 60) {
      canvas.drawLine(Offset(x, 12), Offset(x + 20, 12), line);
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.offset != offset;
}
