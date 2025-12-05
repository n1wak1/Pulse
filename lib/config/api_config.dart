import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Конфигурация API
class ApiConfig {
  // Production сервер
  static const String productionBaseUrl = 'http://176.118.221.246:8081';
  
  // Локальная разработка
  static const String localBaseUrl = 'http://localhost:8080';
  
  // Android эмулятор (используйте порт 8081, не 8080!)
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8081';
  
  // Базовый URL сервера
  // Для использования production сервера замените на productionBaseUrl
  static String get baseUrl {
    // Для Android эмулятора используйте 10.0.2.2:8081 (если бэкенд локально)
    // Или productionBaseUrl для production сервера
    if (Platform.isAndroid) {
      // Используем production сервер по умолчанию
      return productionBaseUrl;
      // Раскомментируйте следующую строку для локальной разработки:
      // return androidEmulatorBaseUrl;
    }
    // Для iOS симулятора и веб используйте localhost:8080 (если бэкенд локально)
    // Или productionBaseUrl для production сервера
    return productionBaseUrl;
    // Раскомментируйте следующую строку для локальной разработки:
    // return localBaseUrl;
  }
  
  // Ключ для сохранения токена в SharedPreferences
  static const String _tokenKey = 'auth_token';
  
  /// Установить токен авторизации (Firebase ID Token)
  static Future<void> setAuthToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
      debugPrint('ApiConfig: Token saved successfully');
      debugPrint('ApiConfig: Token length: ${token.length}');
      debugPrint('ApiConfig: Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      debugPrint('ApiConfig: Token starts with eyJ: ${token.startsWith('eyJ')}');
    } else {
      await prefs.remove(_tokenKey);
      debugPrint('ApiConfig: Token cleared');
    }
  }
  
  /// Получить токен авторизации
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      debugPrint('ApiConfig: Token retrieved');
      debugPrint('ApiConfig: Token length: ${token.length}');
      debugPrint('ApiConfig: Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      debugPrint('ApiConfig: Token starts with eyJ: ${token.startsWith('eyJ')}');
    } else {
      debugPrint('ApiConfig: No token found in storage');
    }
    return token;
  }
  
  /// Очистить токен авторизации
  static Future<void> clearAuthToken() async {
    debugPrint('ApiConfig: Clearing auth token');
    await setAuthToken(null);
  }
}

