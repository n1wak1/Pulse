import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_exception.dart';

/// Базовый класс для работы с API
class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Получение заголовков для запросов
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await ApiConfig.getAuthToken();
    if (token != null) {
      // Проверяем, что токен не пустой
      if (token.isEmpty) {
        debugPrint('ApiClient: Token is empty!');
        throw ApiException('Токен авторизации пустой. Войдите снова.');
      }
      
      // Проверяем, что это ID Token (обычно начинается с "eyJ" для JWT)
      // Custom Token обычно короче и имеет другой формат
      if (!token.startsWith('eyJ')) {
        debugPrint('ApiClient: WARNING - Token does not look like a Firebase ID Token!');
        debugPrint('ApiClient: Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
        debugPrint('ApiClient: Token length: ${token.length}');
        debugPrint('ApiClient: This might be a Custom Token instead of ID Token');
        debugPrint('ApiClient: Custom Tokens cannot be used for API requests - need ID Token');
      }
      
      headers['Authorization'] = 'Bearer $token';
      // Логируем только начало токена для безопасности
      debugPrint(
        'ApiClient: Using token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
      debugPrint('ApiClient: Token length: ${token.length}');
    } else {
      debugPrint('ApiClient: No token found');
      throw ApiException('Токен авторизации отсутствует. Войдите снова.');
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

      debugPrint('ApiClient: GET $endpoint');
      final headers = await _getHeaders();
      debugPrint('ApiClient: Headers keys: ${headers.keys.toList()}');

      final response = await http.get(uri, headers: headers);

      debugPrint('ApiClient: Response status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Ошибка при выполнении GET запроса: $e');
    }
  }

  /// POST запрос
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      debugPrint('ApiClient: Preparing POST request to $endpoint');
      final headers = await _getHeaders();
      final jsonBody = body != null ? jsonEncode(body) : null;
      
      debugPrint('ApiClient: POST $endpoint');
      debugPrint('ApiClient: Headers keys: ${headers.keys.toList()}');
      if (headers.containsKey('Authorization')) {
        final authHeader = headers['Authorization']!;
        debugPrint('ApiClient: Authorization header present: ${authHeader.substring(0, authHeader.length > 30 ? 30 : authHeader.length)}...');
      } else {
        debugPrint('ApiClient: WARNING - Authorization header is missing!');
      }
      debugPrint('ApiClient: Body: $body');
      debugPrint('ApiClient: JSON Body: $jsonBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonBody,
      );

      debugPrint('ApiClient: Response status: ${response.statusCode}');
      debugPrint('ApiClient: Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('ApiClient: POST error: $e');
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
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
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
      // Очищаем токен при 401 ошибке (не ждем завершения, так как это не критично)
      ApiConfig.clearAuthToken().catchError((_) {});
      throw ApiException('Не авторизован. Войдите снова.');
    } else if (response.statusCode == 403) {
      // Ошибка доступа - возможно токен неверный или истек
      debugPrint('ApiClient: 403 Forbidden - возможно проблема с токеном');
      debugPrint('ApiClient: Response body: ${response.body}');
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            errorBody['message'] as String? ??
            errorBody['error'] as String? ??
            'Доступ запрещен';
        ApiConfig.clearAuthToken().catchError((_) {});
        throw ApiException(errorMessage);
      } catch (e) {
        ApiConfig.clearAuthToken().catchError((_) {});
        throw ApiException(
          'Доступ запрещен. Возможно, токен неверный или истек. Войдите снова.',
        );
      }
    } else if (response.statusCode == 404) {
      throw ApiException('Ресурс не найден.');
    } else if (response.statusCode >= 500) {
      throw ApiException('Ошибка сервера. Попробуйте позже.');
    } else {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            errorBody['message'] as String? ??
            errorBody['error'] as String? ??
            'Неизвестная ошибка';
        throw ApiException(errorMessage);
      } catch (e) {
        throw ApiException('Ошибка запроса: ${response.statusCode}');
      }
    }
  }
}
