import 'dart:io';

/// Конфигурация API
class ApiConfig {
  // Базовый URL сервера из swagger.yaml
  // Для Android эмулятора используйте http://10.0.2.2:8080
  // Для iOS симулятора и веб используйте http://localhost:8080
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
  
  // Токен авторизации (Firebase ID Token)
  static String? authToken;
  
  /// Установить токен авторизации
  static void setAuthToken(String? token) {
    authToken = token;
  }
  
  /// Получить токен авторизации
  static String? getAuthToken() {
    return authToken;
  }
}

