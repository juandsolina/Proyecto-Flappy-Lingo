// models/pipe_model.dart
// Representa un par de tubos (superior + inferior) en pantalla.
// Versión 2: incluye datos educativos opcionales.

import 'question_model.dart';

class PipeModel {
  /// Posición X del par de tubos (en píxeles desde el borde izquierdo).
  double x;

  /// Centro Y del hueco entre los dos tubos.
  double gapCenterY;

  /// Alto del hueco entre tubos (espacio por donde pasa el ave).
  final double gapHeight;

  /// Ancho visual del tubo.
  static const double width = 72.0; // un poco más ancho para mostrar texto

  /// Si este par ya fue contado como punto para el jugador.
  bool scored;

  // ── Datos educativos (null = tubo normal sin pregunta) ────────────────────

  /// Pregunta asociada a este par de tubos. null = tubo decorativo.
  final QuestionModel? question;

  /// Si la respuesta correcta está en el tubo SUPERIOR (true) o INFERIOR (false).
  /// Se asigna aleatoriamente al construir el tubo educativo.
  final bool correctIsTop;

  /// Si el jugador ya respondió este tubo (para no volver a evaluarlo).
  bool evaluated;

  /// Centro Y del orificio superior para tubos educativos de 2 orificios.
  final double? upperHoleCenterY;

  /// Centro Y del orificio inferior para tubos educativos de 2 orificios.
  final double? lowerHoleCenterY;

  /// Alto de cada orificio educativo.
  final double? answerHoleHeight;

  PipeModel({
    required this.x,
    required this.gapCenterY,
    this.gapHeight = 245.0,
    this.scored = false,
    this.question,
    this.correctIsTop = true,
    this.evaluated = false,
    this.upperHoleCenterY,
    this.lowerHoleCenterY,
    this.answerHoleHeight,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isEducational => question != null;

  bool get hasAnswerHoles =>
      upperHoleCenterY != null &&
      lowerHoleCenterY != null &&
      answerHoleHeight != null;

  /// Texto que aparece en el tubo superior.
  String? get topLabel => question == null
      ? null
      : (correctIsTop ? question!.correctAnswer : question!.wrongAnswer);

  /// Texto que aparece en el tubo inferior.
  String? get bottomLabel => question == null
      ? null
      : (correctIsTop ? question!.wrongAnswer : question!.correctAnswer);
}
