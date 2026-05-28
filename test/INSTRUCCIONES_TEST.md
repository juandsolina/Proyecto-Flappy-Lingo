# ── Instrucciones para correr las pruebas ─────────────────────────────────────

## 1. Agrega mocktail a pubspec.yaml (dev_dependencies)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

Luego corre:
```bash
flutter pub get
```

## 2. Estructura de archivos de test

Coloca cada archivo en la carpeta `test/` de tu proyecto Flutter:

```
test/
├── physics_engine_test.dart
├── models/
│   ├── question_model_test.dart
│   └── user_model_test.dart
├── game/
│   └── game_controller_test.dart
└── data/
    ├── auth_repository_test.dart
    ├── session_repository_test.dart
    ├── leaderboard_repository_test.dart
    └── question_repository_test.dart
```

## 3. Cambiar el nombre del package en los imports

En todos los archivos, reemplaza `flappy_lingo` con el nombre real
de tu package (el que está en la primera línea de pubspec.yaml):

```yaml
name: tu_nombre_de_package  # ← usa este
```

Ejemplo: si tu package se llama `flappy_lingo_app`, cambia:
```dart
// Antes
import 'package:flappy_lingo/game/physics_engine.dart';

// Después
import 'package:flappy_lingo_app/game/physics_engine.dart';
```

## 4. Correr las pruebas

```bash
# Todas las pruebas
flutter test

# Un archivo específico
flutter test test/physics_engine_test.dart

# Con output detallado
flutter test --reporter expanded

# Solo una prueba por nombre
flutter test --name "flap() aplica fuerza negativa"
```

## 5. Resumen de qué prueba cada archivo

| Archivo                          | Módulo              | Pruebas                                      |
|----------------------------------|---------------------|----------------------------------------------|
| physics_engine_test.dart         | PhysicsEngine       | gravedad, flap, clamp, reset, tiltAngle      |
| question_model_test.dart         | QuestionModel       | fromJson, toJson, round-trip, default cat    |
| user_model_test.dart             | UserModel           | fromJson, toJson, round-trip                 |
| game_controller_test.dart        | GameController      | estados, score, lives, pipes, bestScore      |
| auth_repository_test.dart        | AuthRepository      | parseo login/register, manejo de errores     |
| session_repository_test.dart     | SessionRepository   | save, get, clear, isLoggedIn                 |
| leaderboard_repository_test.dart | LeaderboardRepository | parseo lista, vacía, error HTTP            |
| question_repository_test.dart    | QuestionRepository  | preload, getQuestion, fallback local         |
