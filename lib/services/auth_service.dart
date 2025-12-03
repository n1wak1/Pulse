import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Сервис для авторизации через Firebase
class AuthService {
  late Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  /// Авторизация пользователя
  /// 
  /// Запрос: POST /api/auth/login
  /// Body: { "email": string, "password": string }
  /// 
  /// Ответ: { "token": string, "user": { "id": int, "email": string, "displayName": string? } }
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      // Сохраняем токен
      ApiConfig.setAuthToken(token);

      return AuthResponse(
        token: token,
        user: UserInfo(
          id: userData['id'] as int,
          email: userData['email'] as String,
          displayName: userData['displayName'] as String?,
        ),
      );
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// Регистрация нового пользователя
  /// 
  /// Запрос: POST /api/auth/register
  /// Body: { "email": string, "password": string, "displayName": string? }
  /// 
  /// Ответ: { "token": string, "user": { "id": int, "email": string, "displayName": string? } }
  Future<AuthResponse> register(String email, String password, {String? displayName}) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      // Сохраняем токен
      ApiConfig.setAuthToken(token);

      return AuthResponse(
        token: token,
        user: UserInfo(
          id: userData['id'] as int,
          email: userData['email'] as String,
          displayName: userData['displayName'] as String?,
        ),
      );
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
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
      await _dio.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
        },
      );
      // Успешный ответ - письмо отправлено
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  /// Выход из системы
  void logout() {
    ApiConfig.setAuthToken(null);
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

