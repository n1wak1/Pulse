import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../core/api_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint(
      'LoginScreen: Starting ${_isLoginMode ? "login" : "registration"}',
    );

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authService = AuthService();

    try {
      debugPrint(
        'LoginScreen: Calling ${_isLoginMode ? "login" : "register"} API',
      );

      if (_isLoginMode) {
        // Вход через API
        await authService.login(email, password);
      } else {
        // Регистрация через API
        await authService.register(email, password);
      }

      debugPrint('LoginScreen: Auth successful, navigating to HomeScreen');

      if (!mounted) {
        debugPrint('LoginScreen: Widget not mounted, skipping navigation');
        return;
      }

      // Переход на главный экран после успешной авторизации
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      // Обработка ошибок API
      debugPrint('LoginScreen: ApiException caught: ${e.message}');
      if (!mounted) {
        debugPrint('LoginScreen: Widget not mounted, skipping error display');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, stackTrace) {
      // Обработка других ошибок (сеть, таймаут и т.д.)
      debugPrint('LoginScreen: Exception caught: $e');
      debugPrint('LoginScreen: Stack trace: $stackTrace');
      if (!mounted) {
        debugPrint('LoginScreen: Widget not mounted, skipping error display');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подключения: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      debugPrint('LoginScreen: Finally block executed');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('LoginScreen: Loading state set to false');
      } else {
        debugPrint('LoginScreen: Widget not mounted, cannot update state');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pulse',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kanban и аналитика команды в одном месте',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Вход'),
                        selected: _isLoginMode,
                        onSelected: (value) {
                          if (!value) return;
                          setState(() {
                            _isLoginMode = true;
                            _emailController.clear();
                            _passwordController.clear();
                            _formKey.currentState?.reset();
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Регистрация'),
                        selected: !_isLoginMode,
                        onSelected: (value) {
                          if (!value) return;
                          setState(() {
                            _isLoginMode = false;
                            _emailController.clear();
                            _passwordController.clear();
                            _formKey.currentState?.reset();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFFFAFAFA),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Эл. почта',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите email';
                                }
                                if (!value.contains('@')) {
                                  return 'Некорректный email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: _isLoginMode
                                    ? 'Пароль'
                                    : 'Пароль (минимум 6 символов)',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите пароль';
                                }
                                if (value.length < 6) {
                                  return 'Минимум 6 символов';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode
                                            ? 'Войти'
                                            : 'Создать аккаунт',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Visibility(
                                  visible: _isLoginMode,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Забыли пароль?'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
