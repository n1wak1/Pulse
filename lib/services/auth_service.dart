import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../core/api_exception.dart';

/// Сервис для авторизации через Firebase
class AuthService {
  final String baseUrl;

  AuthService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Авторизация пользователя
  /// 
  /// Запрос: POST /api/auth/login
  /// Body: { "email": string, "password": string }
  /// 
  /// Ответ: { "token": string, "user": { "id": int, "email": string, "displayName": string? } }
  /// 
  /// ⚠️ ВАЖНО: Токен в ответе - это Firebase Custom Token. 
  /// На клиенте его нужно обменять на ID Token через Firebase SDK.
  /// Однако, для упрощения, мы сохраняем Custom Token и используем его напрямую.
  /// В production рекомендуется использовать Firebase SDK для обмена токена.
  Future<AuthResponse> login(String email, String password) async {
    try {
      debugPrint('Login: Sending request to $baseUrl/api/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Login: Request timeout');
          throw ApiException('Превышено время ожидания ответа сервера. Проверьте подключение к интернету.');
        },
      );
      
      debugPrint('Login: Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final customToken = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Обмениваем Custom Token на ID Token через Firebase SDK
        debugPrint('Login: Exchanging Custom Token for ID Token');
        final idToken = await _exchangeCustomTokenForIdToken(customToken);
        
        // Сохраняем ID Token (нужен для работы с API)
        await ApiConfig.setAuthToken(idToken);
        debugPrint('Login: ID Token saved successfully');

        return AuthResponse(
          token: idToken,
          user: UserInfo(
            id: userData['id'] as int,
            email: userData['email'] as String,
            displayName: userData['displayName'] as String?,
          ),
        );
      } else {
        final errorMessage = _parseError(response);
        throw ApiException(errorMessage);
      }
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('Login error (ClientException): $e');
      throw ApiException('Ошибка подключения к серверу. Проверьте интернет-соединение.');
    } on FormatException catch (e) {
      debugPrint('Login error (FormatException): $e');
      throw ApiException('Ошибка формата данных от сервера.');
    } catch (e) {
      debugPrint('Login error: $e');
      throw ApiException('Ошибка при входе: ${e.toString()}');
    }
  }

  /// Регистрация нового пользователя
  /// 
  /// Запрос: POST /api/auth/register
  /// Body: { "email": string, "password": string, "displayName": string? }
  /// 
  /// Ответ: { "token": string, "user": { "id": int, "email": string, "displayName": string? } }
  /// 
  /// ⚠️ ВАЖНО: Токен в ответе - это Firebase Custom Token.
  /// На клиенте его нужно обменять на ID Token через Firebase SDK.
  Future<AuthResponse> register(String email, String password, {String? displayName}) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        // Используем email как displayName, если не указан явно
        'displayName': displayName?.isNotEmpty == true ? displayName : email,
      };

      debugPrint('Register: Sending request to $baseUrl/api/auth/register');
      debugPrint('Register: Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Register: Request timeout');
          throw ApiException('Превышено время ожидания ответа сервера. Проверьте подключение к интернету.');
        },
      );
      
      debugPrint('Register: Response status: ${response.statusCode}');
      debugPrint('Register: Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final customToken = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Обмениваем Custom Token на ID Token через Firebase SDK
        debugPrint('Register: Exchanging Custom Token for ID Token');
        final idToken = await _exchangeCustomTokenForIdToken(customToken);
        
        // Сохраняем ID Token (нужен для работы с API)
        await ApiConfig.setAuthToken(idToken);
        debugPrint('Register: ID Token saved successfully');

        return AuthResponse(
          token: idToken,
          user: UserInfo(
            id: userData['id'] as int,
            email: userData['email'] as String,
            displayName: userData['displayName'] as String?,
          ),
        );
      } else {
        final errorMessage = _parseError(response);
        throw ApiException(errorMessage);
      }
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('Register error (ClientException): $e');
      throw ApiException('Ошибка подключения к серверу. Проверьте интернет-соединение.');
    } on FormatException catch (e) {
      debugPrint('Register error (FormatException): $e');
      throw ApiException('Ошибка формата данных от сервера.');
    } catch (e) {
      debugPrint('Register error: $e');
      throw ApiException('Ошибка при регистрации: ${e.toString()}');
    }
  }

  /// Восстановление пароля
  /// 
  /// Запрос: POST /api/auth/reset-password
  /// Body: { "email": string }
  /// 
  /// Ответ: { "message": string }
  Future<void> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Reset password: Request timeout');
          throw ApiException('Превышено время ожидания ответа сервера. Проверьте подключение к интернету.');
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный ответ - письмо отправлено
        return;
      } else {
        final errorMessage = _parseError(response);
        throw ApiException(errorMessage);
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Ошибка при восстановлении пароля: ${e.toString()}');
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    await ApiConfig.clearAuthToken();
    await FirebaseAuth.instance.signOut();
  }

  /// Обмен Custom Token на ID Token через Firebase SDK
  /// 
  /// Бэкенд возвращает Custom Token, но для работы с API нужен ID Token
  Future<String> _exchangeCustomTokenForIdToken(String customToken) async {
    try {
      debugPrint('AuthService: Signing in with Custom Token');
      
      // Входим в Firebase с Custom Token
      final credential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      
      if (credential.user == null) {
        throw ApiException('Не удалось войти в Firebase с Custom Token');
      }
      
      debugPrint('AuthService: Getting ID Token');
      
      // Получаем ID Token
      final idToken = await credential.user!.getIdToken(true);
      
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Не удалось получить ID Token');
      }
      
      debugPrint('AuthService: ID Token obtained successfully');
      return idToken;
    } catch (e) {
      debugPrint('AuthService: Error exchanging token: $e');
      // Если не удалось обменять токен, пробуем использовать Custom Token напрямую
      // (может не работать для всех эндпоинтов)
      debugPrint('AuthService: Falling back to Custom Token');
      return customToken;
    }
  }

  /// Парсинг ошибки из ответа сервера
  String _parseError(http.Response response) {
    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return errorBody['message'] as String? ?? 
             errorBody['error'] as String? ?? 
             'Неизвестная ошибка';
    } catch (e) {
      if (response.statusCode == 400) {
        return 'Некорректные данные';
      } else if (response.statusCode == 401) {
        return 'Неверные учетные данные';
      } else if (response.statusCode == 404) {
        return 'Ресурс не найден';
      } else if (response.statusCode == 422) {
        return 'Ошибка валидации';
      } else if (response.statusCode >= 500) {
        return 'Ошибка сервера. Попробуйте позже.';
      }
      return 'Ошибка запроса: ${response.statusCode}';
    }
  }
}

/// Ответ авторизации
class AuthResponse {
  final String token;
  final UserInfo user;

  AuthResponse({required this.token, required this.user});
}

/// Информация о пользователе
class UserInfo {
  final int id;
  final String email;
  final String? displayName;

  UserInfo({
    required this.id,
    required this.email,
    this.displayName,
  });
}

