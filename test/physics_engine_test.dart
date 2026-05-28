// test/physics_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/game/physics_engine.dart';

void main() {
  group('PhysicsEngine', () {
    late PhysicsEngine engine;

    setUp(() {
      engine = PhysicsEngine(initialY: 300);
    });

    test('se inicializa con la posición y velocidad correctas', () {
      expect(engine.birdY, 300);
      expect(engine.velocity, 0.0);
    });

    test('update() aplica gravedad cada tick', () {
      engine.update();
      expect(engine.velocity, closeTo(PhysicsEngine.gravity, 0.001));
      expect(engine.birdY, closeTo(300 + PhysicsEngine.gravity, 0.001));
    });

    test('flap() aplica fuerza negativa (hacia arriba)', () {
      engine.flap();
      expect(engine.velocity, PhysicsEngine.flapStrength);
    });

    test('velocidad no supera maxFallSpeed', () {
      for (int i = 0; i < 100; i++) {
        engine.update();
      }
      expect(engine.velocity, lessThanOrEqualTo(PhysicsEngine.maxFallSpeed));
    });

    test('velocidad no supera maxRiseSpeed al bajar (clamp negativo)', () {
      for (int i = 0; i < 10; i++) {
        engine.flap();
      }
      expect(engine.velocity, greaterThanOrEqualTo(PhysicsEngine.maxRiseSpeed));
    });

    test('reset() vuelve a la posición y velocidad iniciales', () {
      engine.flap();
      engine.update();
      engine.reset(500);
      expect(engine.birdY, 500);
      expect(engine.velocity, 0.0);
    });

    test('tiltAngle está dentro del rango [-0.6, 0.8]', () {
      // Con velocidad máxima positiva
      for (int i = 0; i < 100; i++) {
        engine.update();
      }
      expect(engine.tiltAngle, lessThanOrEqualTo(0.8));

      // Con velocidad máxima negativa
      engine.flap();
      expect(engine.tiltAngle, greaterThanOrEqualTo(-0.6));
    });

    test('múltiples flaps seguidos no rompen la física', () {
      engine.flap();
      engine.flap();
      engine.flap();
      engine.update();
      expect(engine.birdY, isNotNull);
      expect(engine.velocity, isNotNull);
    });
  });
}
