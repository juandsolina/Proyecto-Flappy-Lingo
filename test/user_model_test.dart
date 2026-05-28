// test/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/models/user_model.dart';

void main() {
  group('UserModel', () {
    const validJson = {
      'id': 'abc-123',
      'name': 'Juan',
      'email': 'juan@test.com',
    };

    test('fromJson() construye el modelo correctamente', () {
      final user = UserModel.fromJson(validJson);
      expect(user.id, 'abc-123');
      expect(user.name, 'Juan');
      expect(user.email, 'juan@test.com');
    });

    test('toJson() serializa todos los campos correctamente', () {
      final user = UserModel(id: '1', name: 'Ana', email: 'ana@test.com');
      final json = user.toJson();
      expect(json['id'], '1');
      expect(json['name'], 'Ana');
      expect(json['email'], 'ana@test.com');
    });

    test('fromJson() → toJson() es reversible (round-trip)', () {
      final user = UserModel.fromJson(validJson);
      final json = user.toJson();
      final user2 = UserModel.fromJson(json);
      expect(user2.id, user.id);
      expect(user2.name, user.name);
      expect(user2.email, user.email);
    });
  });
}
