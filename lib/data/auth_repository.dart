import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthRepository {
  // ── Login ─────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>;
        return AuthResult(
          success: true,
          message: json['message'] as String,
          token: data['token'] as String,
          user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        );
      }

      return AuthResult(
        success: false,
        message: json['detail'] as String? ??
            json['message'] as String? ??
            'Error desconocido',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository.login] Connection error: $e');
        debugPrint(
            '[AuthRepository.login] URL: ${AppConfig.baseUrl}/api/auth/login');
      }
      return AuthResult(
        success: false,
        message: 'No se pudo conectar al servidor',
      );
    }
  }

  // ── Registro ──────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return AuthResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        message: json['detail'] as String? ??
            json['message'] as String? ??
            'Error desconocido',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository.register] Connection error: $e');
        debugPrint(
            '[AuthRepository.register] URL: ${AppConfig.baseUrl}/api/auth/register');
      }
      return AuthResult(
        success: false,
        message: 'No se pudo conectar al servidor',
      );
    }
  }
}
