import 'package:flutter/material.dart';

class PasswordResetResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String email;
  final String? errorMessage;

  const PasswordResetResultScreen({
    super.key,
    required this.isSuccess,
    required this.email,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановление пароля'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    size: 80,
                    color: isSuccess ? const Color(0xFF73A168) : Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isSuccess ? 'Письмо отправлено' : 'Ошибка',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (isSuccess) ...[
                    Text(
                      'Мы отправили инструкции по восстановлению пароля на адрес:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF73A168).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF73A168),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Что дальше?',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '1. Проверьте почтовый ящик (включая папку "Спам")\n'
                            '2. Откройте письмо от Firebase\n'
                            '3. Перейдите по ссылке в письме\n'
                            '4. Введите новый пароль\n'
                            '5. Войдите в приложение с новым паролем',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ссылка действительна в течение 1 часа.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      errorMessage ?? 'Произошла ошибка при отправке письма',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Возможные причины:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Email не зарегистрирован в системе\n'
                            '• Неверный формат email\n'
                            '• Проблемы с подключением к серверу\n'
                            '• Превышен лимит запросов',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Вернуться к входу'),
                  ),
                  if (!isSuccess) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


