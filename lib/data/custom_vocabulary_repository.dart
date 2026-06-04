import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/custom_vocabulary_item_model.dart';
import 'session_repository.dart';

class CrudResult<T> {
  final bool success;
  final String message;
  final T? data;

  const CrudResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class CustomVocabularyRepository {
  final SessionRepository _session = SessionRepository();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<CrudResult<List<CustomVocabularyItem>>> list(
      {String? category}) async {
    try {
      final headers = await _authHeaders();
      final query = (category == null || category.trim().isEmpty)
          ? ''
          : '?category=${Uri.encodeQueryComponent(category.trim())}';
      final uri = Uri.parse('${AppConfig.customVocabularyEndpoint}$query');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 8),
          );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true) {
        final raw = decoded['data'] as List<dynamic>;
        final items = raw
            .whereType<Map<String, dynamic>>()
            .map(CustomVocabularyItem.fromJson)
            .toList();
        return CrudResult(success: true, message: 'OK', data: items);
      }

      return CrudResult(
        success: false,
        message:
            decoded['detail'] as String? ?? 'Error al consultar vocabulario',
      );
    } catch (e) {
      return CrudResult(success: false, message: e.toString());
    }
  }

  Future<CrudResult<CustomVocabularyItem>> create({
    required String wordInSpanish,
    required String correctAnswer,
    required String wrongAnswer,
    required String category,
  }) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(AppConfig.customVocabularyEndpoint);

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'word_in_spanish': wordInSpanish,
              'correct_answer': correctAnswer,
              'wrong_answer': wrongAnswer,
              'category': category,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          decoded['success'] == true) {
        final item = CustomVocabularyItem.fromJson(
          decoded['data'] as Map<String, dynamic>,
        );
        return CrudResult(
          success: true,
          message: decoded['message'] as String? ?? 'Creado',
          data: item,
        );
      }

      return CrudResult(
        success: false,
        message: decoded['detail'] as String? ?? 'Error al crear vocabulario',
      );
    } catch (e) {
      return CrudResult(success: false, message: e.toString());
    }
  }

  Future<CrudResult<CustomVocabularyItem>> update({
    required int id,
    required String wordInSpanish,
    required String correctAnswer,
    required String wrongAnswer,
    required String category,
  }) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${AppConfig.customVocabularyEndpoint}/$id');

      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode({
              'word_in_spanish': wordInSpanish,
              'correct_answer': correctAnswer,
              'wrong_answer': wrongAnswer,
              'category': category,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true) {
        final item = CustomVocabularyItem.fromJson(
          decoded['data'] as Map<String, dynamic>,
        );
        return CrudResult(
          success: true,
          message: decoded['message'] as String? ?? 'Actualizado',
          data: item,
        );
      }

      return CrudResult(
        success: false,
        message:
            decoded['detail'] as String? ?? 'Error al actualizar vocabulario',
      );
    } catch (e) {
      return CrudResult(success: false, message: e.toString());
    }
  }

  Future<CrudResult<void>> remove(int id) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${AppConfig.customVocabularyEndpoint}/$id');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true) {
        return CrudResult(
            success: true,
            message: decoded['message'] as String? ?? 'Eliminado');
      }

      return CrudResult(
        success: false,
        message:
            decoded['detail'] as String? ?? 'Error al eliminar vocabulario',
      );
    } catch (e) {
      return CrudResult(success: false, message: e.toString());
    }
  }
}
