// test/data/session_repository_test.dart
//
// Requiere en pubspec.yaml (dev_dependencies):
//   shared_preferences: (ya está en dependencies)
//
// Flutter test configura SharedPreferences con un backend en memoria.
//
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_lingo/data/session_repository.dart';
import 'package:flappy_lingo/models/user_model.dart';

void main() {
  group('SessionRepository', () {
    late SessionRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = SessionRepository();
    });

    test('getToken() retorna null si no hay sesión guardada', () async {
      final token = await repo.getToken();
      expect(token, isNull);
    });

    test('getUser() retorna null si no hay sesión guardada', () async {
      final user = await repo.getUser();
      expect(user, isNull);
    });

    test('isLoggedIn() retorna false si no hay sesión', () async {
      final loggedIn = await repo.isLoggedIn();
      expect(loggedIn, false);
    });

    test('saveSession() guarda token y usuario correctamente', () async {
      final user = UserModel(id: '1', name: 'Ana', email: 'ana@test.com');
      await repo.saveSession(token: 'mi-token-jwt', user: user);

      final token = await repo.getToken();
      expect(token, 'mi-token-jwt');
    });

    test('getUser() retorna el usuario guardado con saveSession()', () async {
      final user =
          UserModel(id: '42', name: 'Carlos', email: 'carlos@test.com');
      await repo.saveSession(token: 'token-abc', user: user);

      final recovered = await repo.getUser();
      expect(recovered, isNotNull);
      expect(recovered!.id, '42');
      expect(recovered.name, 'Carlos');
      expect(recovered.email, 'carlos@test.com');
    });

    test('isLoggedIn() retorna true después de guardar sesión', () async {
      final user = UserModel(id: '1', name: 'Test', email: 'test@test.com');
      await repo.saveSession(token: 'token-valido', user: user);

      final loggedIn = await repo.isLoggedIn();
      expect(loggedIn, true);
    });

    test('clearSession() elimina token y usuario', () async {
      final user = UserModel(id: '1', name: 'Test', email: 'test@test.com');
      await repo.saveSession(token: 'token-valido', user: user);
      await repo.clearSession();

      expect(await repo.getToken(), isNull);
      expect(await repo.getUser(), isNull);
      expect(await repo.isLoggedIn(), false);
    });

    test('saveSession() sobreescribe sesión anterior', () async {
      final user1 = UserModel(id: '1', name: 'Uno', email: 'uno@test.com');
      final user2 = UserModel(id: '2', name: 'Dos', email: 'dos@test.com');

      await repo.saveSession(token: 'token-1', user: user1);
      await repo.saveSession(token: 'token-2', user: user2);

      expect(await repo.getToken(), 'token-2');
      final u = await repo.getUser();
      expect(u!.name, 'Dos');
    });
  });
}
