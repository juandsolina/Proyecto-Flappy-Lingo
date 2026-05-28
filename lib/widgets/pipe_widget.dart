// widgets/pipe_widget.dart
// Versión 2: dibuja el texto de la opción en el cuerpo del tubo superior/inferior.

import 'package:flutter/material.dart';
import '../models/pipe_model.dart';

class PipeWidget extends StatelessWidget {
  final PipeModel pipe;
  final double screenHeight;

  const PipeWidget({
    super.key,
    required this.pipe,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: pipe.x,
      top: 0,
      // Stack para superponer los textos sobre el CustomPainter.
      child: SizedBox(
        width: PipeModel.width,
        height: screenHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Tubo dibujado con CustomPainter ──────────────────────────
            CustomPaint(
              size: Size(PipeModel.width, screenHeight),
              painter: pipe.hasAnswerHoles
                  ? _EducationalPipePainter(
                      upperHoleCenterY: pipe.upperHoleCenterY!,
                      lowerHoleCenterY: pipe.lowerHoleCenterY!,
                      holeHeight: pipe.answerHoleHeight!,
                    )
                  : _PipePainter(
                      gapCenterY: pipe.gapCenterY,
                      gapHeight: pipe.gapHeight,
                    ),
            ),

            // ── Guía visual en el hueco (verde/rojo) para tubos educativos ──
            if (pipe.isEducational && pipe.hasAnswerHoles)
              _DecisionZoneGuide(
                upperHoleCenterY: pipe.upperHoleCenterY!,
                lowerHoleCenterY: pipe.lowerHoleCenterY!,
                holeHeight: pipe.answerHoleHeight!,
                correctIsTop: pipe.correctIsTop,
              ),

            // ── Etiqueta en tubo SUPERIOR ─────────────────────────────────
            if (pipe.topLabel != null)
              _PipeLabel(
                label: pipe.topLabel!,
                top: pipe.hasAnswerHoles
                    ? pipe.upperHoleCenterY! - 14
                    : (pipe.gapCenterY - pipe.gapHeight / 2) / 2 - 14,
              ),

            // ── Etiqueta en tubo INFERIOR ─────────────────────────────────
            if (pipe.bottomLabel != null)
              _PipeLabel(
                label: pipe.bottomLabel!,
                top: pipe.hasAnswerHoles
                    ? pipe.lowerHoleCenterY! - 14
                    : (pipe.gapCenterY + pipe.gapHeight / 2) +
                        (screenHeight - pipe.gapCenterY - pipe.gapHeight / 2) /
                            2 -
                        14,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Etiqueta de opción sobre el tubo ─────────────────────────────────────────

class _PipeLabel extends StatelessWidget {
  final String label;
  final double top;

  const _PipeLabel({required this.label, required this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _DecisionZoneGuide extends StatelessWidget {
  final double upperHoleCenterY;
  final double lowerHoleCenterY;
  final double holeHeight;
  final bool correctIsTop;

  const _DecisionZoneGuide({
    required this.upperHoleCenterY,
    required this.lowerHoleCenterY,
    required this.holeHeight,
    required this.correctIsTop,
  });

  @override
  Widget build(BuildContext context) {
    final topHoleTop = upperHoleCenterY - holeHeight / 2;
    final bottomHoleTop = lowerHoleCenterY - holeHeight / 2;

    return Stack(
      children: [
        Positioned(
          top: topHoleTop,
          left: 0,
          right: 0,
          height: holeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
          ),
        ),
        Positioned(
          top: bottomHoleTop,
          left: 0,
          right: 0,
          height: holeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EducationalPipePainter extends CustomPainter {
  final double upperHoleCenterY;
  final double lowerHoleCenterY;
  final double holeHeight;

  const _EducationalPipePainter({
    required this.upperHoleCenterY,
    required this.lowerHoleCenterY,
    required this.holeHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final upperTop = upperHoleCenterY - holeHeight / 2;
    final upperBottom = upperHoleCenterY + holeHeight / 2;
    final lowerTop = lowerHoleCenterY - holeHeight / 2;
    final lowerBottom = lowerHoleCenterY + holeHeight / 2;

    final bodyPaint = Paint()..color = const Color(0xFF43A047);
    final shadowPaint = Paint()..color = const Color(0xFF2E7D32);
    final lightPaint = Paint()..color = const Color(0xFF66BB6A);

    void drawPipeSegment(double top, double bottom) {
      final height = bottom - top;
      if (height <= 0) return;

      canvas.drawRect(Rect.fromLTWH(0, top, w, height), bodyPaint);
      canvas.drawRect(Rect.fromLTWH(0, top, w * 0.15, height), shadowPaint);
      canvas.drawRect(
          Rect.fromLTWH(w * 0.82, top, w * 0.18, height), lightPaint);
    }

    drawPipeSegment(0, upperTop);
    drawPipeSegment(upperBottom, lowerTop);
    drawPipeSegment(lowerBottom, h);

    _drawCap(
        canvas: canvas,
        top: upperTop - 10,
        capHeight: 10,
        pipeWidth: w,
        capExtraWidth: 8);
    _drawCap(
        canvas: canvas,
        top: upperBottom,
        capHeight: 10,
        pipeWidth: w,
        capExtraWidth: 8);
    _drawCap(
        canvas: canvas,
        top: lowerTop - 10,
        capHeight: 10,
        pipeWidth: w,
        capExtraWidth: 8);
    _drawCap(
        canvas: canvas,
        top: lowerBottom,
        capHeight: 10,
        pipeWidth: w,
        capExtraWidth: 8);
  }

  void _drawCap({
    required Canvas canvas,
    required double top,
    required double capHeight,
    required double pipeWidth,
    required double capExtraWidth,
  }) {
    final capPaint = Paint()..color = const Color(0xFF388E3C);
    final capShadow = Paint()..color = const Color(0xFF2E7D32);
    final capLight = Paint()..color = const Color(0xFF66BB6A);
    final capLeft = -capExtraWidth / 2;
    final capWidth = pipeWidth + capExtraWidth;

    canvas.drawRect(Rect.fromLTWH(capLeft, top, capWidth, capHeight), capPaint);
    canvas.drawRect(
      Rect.fromLTWH(capLeft, top, capWidth * 0.12, capHeight),
      capShadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(capLeft + capWidth * 0.84, top, capWidth * 0.16, capHeight),
      capLight,
    );
  }

  @override
  bool shouldRepaint(_EducationalPipePainter old) =>
      old.upperHoleCenterY != upperHoleCenterY ||
      old.lowerHoleCenterY != lowerHoleCenterY ||
      old.holeHeight != holeHeight;
}

// ── CustomPainter del tubo (igual que v1) ─────────────────────────────────────

class _PipePainter extends CustomPainter {
  final double gapCenterY;
  final double gapHeight;

  const _PipePainter({required this.gapCenterY, required this.gapHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final topPipeBottom = gapCenterY - gapHeight / 2;
    final bottomPipeTop = gapCenterY + gapHeight / 2;

    final bodyPaint = Paint()..color = const Color(0xFF43A047);
    final shadowPaint = Paint()..color = const Color(0xFF2E7D32);
    final lightPaint = Paint()..color = const Color(0xFF66BB6A);

    // Tubo superior
    canvas.drawRect(Rect.fromLTWH(0, 0, w, topPipeBottom), bodyPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.15, topPipeBottom), shadowPaint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.82, 0, w * 0.18, topPipeBottom), lightPaint);
    _drawCap(
        canvas: canvas,
        top: topPipeBottom - 20,
        capHeight: 20,
        pipeWidth: w,
        capExtraWidth: 8);

    // Tubo inferior
    final bottomHeight = size.height - bottomPipeTop;
    canvas.drawRect(
        Rect.fromLTWH(0, bottomPipeTop, w, bottomHeight), bodyPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, bottomPipeTop, w * 0.15, bottomHeight), shadowPaint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.82, bottomPipeTop, w * 0.18, bottomHeight),
        lightPaint);
    _drawCap(
        canvas: canvas,
        top: bottomPipeTop,
        capHeight: 20,
        pipeWidth: w,
        capExtraWidth: 8);
  }

  void _drawCap({
    required Canvas canvas,
    required double top,
    required double capHeight,
    required double pipeWidth,
    required double capExtraWidth,
  }) {
    final capPaint = Paint()..color = const Color(0xFF388E3C);
    final capShadow = Paint()..color = const Color(0xFF2E7D32);
    final capLight = Paint()..color = const Color(0xFF66BB6A);
    final capLeft = -capExtraWidth / 2;
    final capWidth = pipeWidth + capExtraWidth;

    canvas.drawRect(Rect.fromLTWH(capLeft, top, capWidth, capHeight), capPaint);
    canvas.drawRect(
        Rect.fromLTWH(capLeft, top, capWidth * 0.12, capHeight), capShadow);
    canvas.drawRect(
        Rect.fromLTWH(
            capLeft + capWidth * 0.84, top, capWidth * 0.16, capHeight),
        capLight);
  }

  @override
  bool shouldRepaint(_PipePainter old) =>
      old.gapCenterY != gapCenterY || old.gapHeight != gapHeight;
}
