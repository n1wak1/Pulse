import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'notifiers/current_project_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'config/api_config.dart';

const Color kPrimaryColor = Color(0xFF73A168);
const Color kBackgroundColor = Color(0xFFFAFAFA);
const Color kTextColor = Color(0xFF000000);
const Color kActionButtonColor = Color(0xFF636363);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  // Примечание: Для работы нужны файлы google-services.json (Android) и GoogleService-Info.plist (iOS)
  // Если файлы отсутствуют, Firebase будет инициализирован с ошибкой, но приложение продолжит работу
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Приложение будет работать, но обмен токенов может не работать');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => CurrentProjectNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Проверяем авторизацию через Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    
    if (firebaseUser != null) {
      // Если пользователь авторизован в Firebase, получаем токен
      try {
        final token = await firebaseUser.getIdToken(true);
        if (token != null && token.isNotEmpty) {
          await ApiConfig.setAuthToken(token);
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error getting token: $e');
      }
    }
    
    // Если пользователь не авторизован, очищаем токен
    await ApiConfig.clearAuthToken();
    setState(() {
      _isAuthenticated = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: kTextColor,
      displayColor: kTextColor,
    );

    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kActionButtonColor,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: kTextColor,
        ),
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: baseTextTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: kTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kActionButtonColor),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
