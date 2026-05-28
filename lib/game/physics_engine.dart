class PhysicsEngine {
  static const double gravity = 0.3;
  static const double flapStrength = -7.0;
  static const double maxFallSpeed = 8.0;
  static const double maxRiseSpeed = -8.0;

  double birdY;
  double _velocity = 0.0;

  PhysicsEngine({required double initialY}) : birdY = initialY;

  double get velocity => _velocity;

  double get tiltAngle {
    // Negative velocity tilts up, positive tilts down.
    return (_velocity / 10).clamp(-0.6, 0.8);
  }

  void flap() {
    _velocity = flapStrength;
  }

  void update() {
    _velocity += gravity;
    _velocity = _velocity.clamp(maxRiseSpeed, maxFallSpeed);
    birdY += _velocity;
  }

  void reset(double y) {
    birdY = y;
    _velocity = 0.0;
  }
}
