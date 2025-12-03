import 'package:flutter/material.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Подключить API авторизации/регистрации через Firebase
      // 
      // Процесс:
      // 1. Приложение отправляет email и password на бэкенд
      // 2. Бэкенд авторизует пользователя в Firebase
      // 3. Бэкенд возвращает токен (Firebase ID Token или JWT)
      // 4. Приложение сохраняет токен и переходит на экран с задачами
      // 
      // Для логина: POST /api/auth/login
      // Для регистрации: POST /api/auth/register
      // 
      // Пример запроса для логина:
      // final email = _emailController.text.trim();
      // final password = _passwordController.text;
      // final response = await http.post(
      //   Uri.parse('http://localhost:8080/api/auth/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
      //     'password': password,
      //   }),
      // );
      // 
      // Пример запроса для регистрации:
      // final response = await http.post(
      //   Uri.parse('http://localhost:8080/api/auth/register'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
      //     'password': password,
      //     'displayName': 'Имя пользователя', // опционально
      //   }),
      // );
      //
      // После успешной авторизации:
      // 1. Получить токен из ответа: final token = responseData['token'];
      // 2. Сохранить токен в безопасное хранилище
      // 3. Перейти на экран с задачами:
      //    Navigator.pushReplacement(
      //      context,
      //      MaterialPageRoute(builder: (_) => const TaskScreen()),
      //    );

      // Временная заглушка - имитация задержки
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Временное сообщение (замените на реальную логику)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode
                ? 'Успешный вход (подключите API)'
                : 'Успешная регистрация (подключите API)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Обработка ошибок
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      color: Colors.black.withOpacity(0.7),
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
                                labelText: 'Email',
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
                                labelText:
                                    _isLoginMode ? 'Пароль' : 'Пароль (минимум 6 символов)',
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
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(_isLoginMode ? 'Войти' : 'Создать аккаунт'),
                              ),
                            ),
                            if (_isLoginMode) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Восстановление пароля реализует бекенд'),
                                      ),
                                    );
                                  },
                                  child: const Text('Забыли пароль?'),
                                ),
                              ),
                            ],
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

