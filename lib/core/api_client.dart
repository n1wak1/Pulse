import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Базовый класс для работы с API
class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Получение заголовков для запросов
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = ApiConfig.getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET запрос (возвращает динамический тип для поддержки массивов)
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Ошибка при выполнении GET запроса: $e');
    }
  }

  /// POST запрос
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Ошибка при выполнении POST запроса: $e');
    }
  }

  /// PUT запрос
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Ошибка при выполнении PUT запроса: $e');
    }
  }

  /// DELETE запрос
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Ошибка при выполнении DELETE запроса: $e');
    }
  }

  /// Обработка ответа от сервера (возвращает динамический тип)
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      
      try {
        final decoded = jsonDecode(response.body);
        // Возвращаем как есть - может быть Map или List
        return decoded;
      } catch (e) {
        throw ApiException('Ошибка парсинга JSON: $e');
      }
    } else if (response.statusCode == 401) {
      throw ApiException('Не авторизован. Проверьте токен доступа.');
    } else if (response.statusCode == 404) {
      throw ApiException('Ресурс не найден.');
    } else if (response.statusCode >= 500) {
      throw ApiException('Ошибка сервера. Попробуйте позже.');
    } else {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['message'] as String? ?? 
                           errorBody['error'] as String? ?? 
                           'Неизвестная ошибка';
        throw ApiException(errorMessage);
      } catch (e) {
        throw ApiException('Ошибка запроса: ${response.statusCode}');
      }
    }
  }
}

/// Исключение для ошибок API
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

