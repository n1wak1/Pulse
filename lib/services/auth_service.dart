import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../core/api_exception.dart';

/// Сервис для авторизации через Firebase
/// 
/// ВСЯ авторизация происходит напрямую через Firebase SDK.
/// Бэкенд НЕ участвует в регистрации и логине - только валидирует токены.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Авторизация пользователя через Firebase SDK
  /// 
  /// Пароль проверяется СТРОГО через Firebase - только при 100% совпадении возвращается токен.
  Future<AuthResponse> login(String email, String password) async {
    try {
      debugPrint('Login: Attempting to sign in with Firebase');
      debugPrint('Login: Email: $email');
      
      // Входим через Firebase SDK - пароль проверяется автоматически
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw ApiException('Не удалось войти в систему');
      }
      
      debugPrint('Login: Firebase sign in successful, user: ${credential.user!.uid}');
      
      // Получаем ID Token
      final idToken = await credential.user!.getIdToken(true);
      
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Не удалось получить токен авторизации');
      }
      
      // Проверяем формат токена
      if (!idToken.startsWith('eyJ')) {
        debugPrint('Login: WARNING - Token does not look like a Firebase ID Token!');
        throw ApiException('Неверный формат токена');
      }
      
      // Сохраняем ID Token для работы с API
      await ApiConfig.setAuthToken(idToken);
      debugPrint('Login: ID Token saved successfully (length: ${idToken.length})');

      return AuthResponse(
        token: idToken,
        user: UserInfo(
          id: 0, // ID будет получен с бэкенда при первом запросе
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Login: FirebaseAuthException: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Неверный email или пароль';
          break;
        case 'user-disabled':
          errorMessage = 'Аккаунт заблокирован';
          break;
        case 'too-many-requests':
          errorMessage = 'Слишком много попыток. Попробуйте позже';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        default:
          errorMessage = 'Ошибка входа: ${e.message ?? e.code}';
      }
      
      throw ApiException(errorMessage);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Login error: $e');
      throw ApiException('Ошибка при входе: ${e.toString()}');
    }
  }

  /// Регистрация нового пользователя через Firebase SDK
  /// 
  /// Пользователь регистрируется напрямую в Firebase.
  /// Бэкенд НЕ участвует в регистрации - только валидирует токены при запросах.
  Future<AuthResponse> register(String email, String password, {String? displayName}) async {
    try {
      debugPrint('Register: Attempting to create user in Firebase');
      debugPrint('Register: Email: $email');
      
      // Создаем пользователя в Firebase через SDK
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw ApiException('Не удалось создать аккаунт');
      }
      
      debugPrint('Register: Firebase user created successfully, UID: ${credential.user!.uid}');
      
      // Обновляем displayName, если указан
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }
      
      // Получаем ID Token
      final idToken = await credential.user!.getIdToken(true);
      
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Не удалось получить токен авторизации');
      }
      
      // Проверяем формат токена
      if (!idToken.startsWith('eyJ')) {
        debugPrint('Register: WARNING - Token does not look like a Firebase ID Token!');
        throw ApiException('Неверный формат токена');
      }
      
      // Сохраняем ID Token для работы с API
      await ApiConfig.setAuthToken(idToken);
      debugPrint('Register: ID Token saved successfully (length: ${idToken.length})');

      return AuthResponse(
        token: idToken,
        user: UserInfo(
          id: 0, // ID будет получен с бэкенда при первом запросе
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? displayName,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Register: FirebaseAuthException: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email уже используется';
          break;
        case 'invalid-email':
          errorMessage = 'Некорректный email';
          break;
        case 'weak-password':
          errorMessage = 'Пароль слишком слабый';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        default:
          errorMessage = 'Ошибка регистрации: ${e.message ?? e.code}';
      }
      
      throw ApiException(errorMessage);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Register error: $e');
      throw ApiException('Ошибка при регистрации: ${e.toString()}');
    }
  }

  /// Восстановление пароля через Firebase SDK
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Reset password: Sending password reset email to $email');
      
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      
      debugPrint('Reset password: Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset password: FirebaseAuthException: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с таким email не найден';
          break;
        case 'invalid-email':
          errorMessage = 'Некорректный email';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        default:
          errorMessage = 'Ошибка восстановления пароля: ${e.message ?? e.code}';
      }
      
      throw ApiException(errorMessage);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Reset password error: $e');
      throw ApiException('Ошибка при восстановлении пароля: ${e.toString()}');
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    await ApiConfig.clearAuthToken();
    await FirebaseAuth.instance.signOut();
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