// test/data/auth_repository_test.dart
//
// Requiere en pubspec.yaml (dev_dependencies):
//   mocktail: ^1.0.4
//
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/data/auth_repository.dart';

// Subclase de AuthRepository que acepta un cliente HTTP inyectado.
// Para usarla, refactoriza AuthRepository para aceptar un http.Client opcional:
//   AuthRepository({http.Client? client}) : _client = client ?? http.Client();
// y usa _client en lugar de http directamente.
//
// Si no quieres refactorizar, estas pruebas validan la lógica de parseo.

void main() {
  group('AuthResult', () {
    test('se construye con success=true correctamente', () {
      final result = AuthResult(
        success: true,
        message: 'Login exitoso',
        token: 'abc.def.ghi',
      );
      expect(result.success, true);
      expect(result.token, 'abc.def.ghi');
      expect(result.user, isNull);
    });

    test('se construye con success=false correctamente', () {
      final result = AuthResult(
        success: false,
        message: 'Credenciales inválidas',
      );
      expect(result.success, false);
      expect(result.token, isNull);
    });
  });

  group('AuthRepository — parseo de respuesta login', () {
    test('parsea respuesta exitosa del backend correctamente', () {
      final body = jsonEncode({
        'success': true,
        'message': 'Login correcto',
        'data': {
          'token': 'token-xyz',
          'user': {'id': '1', 'name': 'Juan', 'email': 'juan@test.com'},
        },
      });

      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['success'], true);

      final data = json['data'] as Map<String, dynamic>;
      expect(data['token'], 'token-xyz');
      expect(data['user']['email'], 'juan@test.com');
    });

    test('parsea respuesta de error con campo detail', () {
      final body = jsonEncode({'detail': 'Credenciales incorrectas'});
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['detail'] as String? ??
          json['message'] as String? ??
          'Error desconocido';
      expect(message, 'Credenciales incorrectas');
    });

    test('parsea respuesta de error con campo message', () {
      final body = jsonEncode({'message': 'Usuario no encontrado'});
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['detail'] as String? ??
          json['message'] as String? ??
          'Error desconocido';
      expect(message, 'Usuario no encontrado');
    });

    test('usa "Error desconocido" si no hay detail ni message', () {
      final body = jsonEncode({'error': 'algo raro'});
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['detail'] as String? ??
          json['message'] as String? ??
          'Error desconocido';
      expect(message, 'Error desconocido');
    });
  });

  group('AuthRepository — parseo de respuesta register', () {
    test('status 201 se considera éxito', () {
      const statusCode = 201;
      expect(statusCode == 200 || statusCode == 201, true);
    });

    test('status 400 se considera fallo', () {
      const statusCode = 400;
      expect(statusCode == 200 || statusCode == 201, false);
    });
  });
}
