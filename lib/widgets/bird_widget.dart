import 'package:flutter/material.dart';

class BirdWidget extends StatefulWidget {
  final double velocity;
  final double? x;
  final double? y;
  final double? radius;
  final double? tiltAngle;

  const BirdWidget({
    super.key,
    this.velocity = 0,
    this.x,
    this.y,
    this.radius,
    this.tiltAngle,
  });

  @override
  State<BirdWidget> createState() => _BirdWidgetState();
}

class _BirdWidgetState extends State<BirdWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flapController;
  late Animation<double> _flapAnim;

  @override
  void initState() {
    super.initState();
    _flapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);
    _flapAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = (widget.radius != null) ? widget.radius! * 2 : 44;
    final double tilt =
        widget.tiltAngle ?? (widget.velocity / 600).clamp(-0.4, 0.6);

    final bird = Transform.rotate(
      angle: tilt,
      child: AnimatedBuilder(
        animation: _flapAnim,
        builder: (_, __) => CustomPaint(
          size: Size(size, size),
          painter: _BirdPainter(_flapAnim.value),
        ),
      ),
    );

    if (widget.x != null && widget.y != null) {
      return Positioned(
        left: widget.x! - size / 2,
        top: widget.y! - size / 2,
        child: bird,
      );
    }
    return bird;
  }
}

class _BirdPainter extends CustomPainter {
  final double flapT; // 0.0 → 1.0
  _BirdPainter(this.flapT);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Ala trasera (detrás del cuerpo) ──────────────────────────────────
    final backWingAngle = _lerpD(-0.2, 0.5, flapT);
    _drawWing(canvas, cx - 4, cy + 2, w * 0.38, backWingAngle,
        const Color(0xFFE65100),
        mirrored: false, opacity: 0.7);

    // ── Cuerpo principal ──────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFFFD740), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.42));

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: w * 0.82, height: h * 0.78),
      bodyPaint,
    );

    // Brillo del cuerpo
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.1, cy - h * 0.15),
          width: w * 0.3,
          height: h * 0.22),
      shinePaint,
    );

    // ── Ala delantera ─────────────────────────────────────────────────────
    final frontWingAngle = _lerpD(-0.3, 0.6, flapT);
    _drawWing(
        canvas, cx, cy - 2, w * 0.4, frontWingAngle, const Color(0xFFFF6F00),
        mirrored: false, opacity: 1.0);

    // ── Cola ──────────────────────────────────────────────────────────────
    _drawTail(canvas, cx - w * 0.35, cy, w, h);

    // ── Pecho más claro ───────────────────────────────────────────────────
    final chestPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + w * 0.08, cy + h * 0.1),
          width: w * 0.38,
          height: h * 0.32),
      chestPaint,
    );

    // ── Ojo ───────────────────────────────────────────────────────────────
    final eyeX = cx + w * 0.18;
    final eyeY = cy - h * 0.12;

    // Esclerótica
    canvas.drawCircle(
        Offset(eyeX, eyeY), w * 0.13, Paint()..color = Colors.white);
    // Iris
    canvas.drawCircle(Offset(eyeX + 1, eyeY), w * 0.08,
        Paint()..color = const Color(0xFF1A237E));
    // Pupila
    canvas.drawCircle(
        Offset(eyeX + 1.5, eyeY), w * 0.04, Paint()..color = Colors.black);
    // Brillo del ojo
    canvas.drawCircle(
        Offset(eyeX - 1, eyeY - 2), w * 0.025, Paint()..color = Colors.white);

    // ── Pico ──────────────────────────────────────────────────────────────
    _drawBeak(canvas, cx + w * 0.35, cy + h * 0.05, w);
  }

  void _drawWing(Canvas canvas, double x, double y, double length, double angle,
      Color color,
      {required bool mirrored, required double opacity}) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -length * 0.3, length, 0)
      ..quadraticBezierTo(length * 0.5, length * 0.25, 0, 0);

    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: opacity),
    );

    // Plumas: líneas sobre el ala
    final featherPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      canvas.drawLine(
        Offset(length * t * 0.4, 0),
        Offset(length * t, -length * 0.15),
        featherPaint,
      );
    }
    canvas.restore();
  }

  void _drawTail(Canvas canvas, double x, double y, double w, double h) {
    final path = Path()
      ..moveTo(x, y - h * 0.1)
      ..lineTo(x - w * 0.18, y - h * 0.22)
      ..lineTo(x - w * 0.12, y)
      ..lineTo(x - w * 0.2, y + h * 0.18)
      ..lineTo(x, y + h * 0.1)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFE65100));
  }

  void _drawBeak(Canvas canvas, double x, double y, double w) {
    // Mandíbula superior
    final upper = Path()
      ..moveTo(x, y - w * 0.06)
      ..lineTo(x + w * 0.18, y)
      ..lineTo(x, y + w * 0.02)
      ..close();
    canvas.drawPath(upper, Paint()..color = const Color(0xFFFF8F00));

    // Mandíbula inferior
    final lower = Path()
      ..moveTo(x, y + w * 0.02)
      ..lineTo(x + w * 0.14, y + w * 0.07)
      ..lineTo(x, y + w * 0.09)
      ..close();
    canvas.drawPath(lower, Paint()..color = const Color(0xFFFFB300));
  }

  double _lerpD(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_BirdPainter old) => old.flapT != flapT;
}
