import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/team_member.dart';
import '../models/team_data.dart';
import '../models/team_response.dart';
import '../services/team_service.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import 'login_screen.dart';

class CreateTeamScreen extends StatefulWidget {
  final Function(TeamData)? onTeamCreated;

  const CreateTeamScreen({super.key, this.onTeamCreated});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  // Цвета
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);
  static const Color accentColor = Color(0xFF73A168);
  static const Color textColor = Color(0xFF000000);

  // Контроллеры для полей ввода
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();

  // Контроллеры для участников
  final List<TextEditingController> _roleControllers = [];
  final List<TextEditingController> _nicknameControllers = [];

  @override
  void initState() {
    super.initState();
    // Добавляем одно поле для участника по умолчанию
    _addMemberField();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    for (var controller in _roleControllers) {
      controller.dispose();
    }
    for (var controller in _nicknameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() {
      _roleControllers.add(TextEditingController());
      _nicknameControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_roleControllers.length > 1) {
      setState(() {
        _roleControllers[index].dispose();
        _nicknameControllers[index].dispose();
        _roleControllers.removeAt(index);
        _nicknameControllers.removeAt(index);
      });
    }
  }

  Future<void> _createTeam() async {
    if (_formKey.currentState!.validate()) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Создаем сервис для работы с API
        final apiClient = ApiClient();
        final teamService = TeamService(apiClient);

        // Собираем участников для отправки на сервер
        final participants = <Map<String, String>>[];
        for (int i = 0; i < _roleControllers.length; i++) {
          final role = _roleControllers[i].text.trim();
          final nickname = _nicknameControllers[i].text.trim();
          
          if (role.isNotEmpty && nickname.isNotEmpty) {
            participants.add({
              'name': nickname,
              'role': role,
            });
          }
        }

        final teamName = _teamNameController.text.trim();
        final description = _descriptionController.text.trim();
        
        debugPrint('CreateTeamScreen: Preparing request');
        debugPrint('CreateTeamScreen:   name: "$teamName"');
        debugPrint('CreateTeamScreen:   description: "$description"');
        debugPrint('CreateTeamScreen:   participants count: ${participants.length}');
        for (int i = 0; i < participants.length; i++) {
          debugPrint('CreateTeamScreen:     participant $i: ${participants[i]}');
        }

        // Создаем запрос на создание команды
        final createRequest = CreateTeamRequest(
          name: teamName,
          description: description.isNotEmpty ? description : null,
          participants: participants.isNotEmpty ? participants : null,
        );
        
        debugPrint('CreateTeamScreen: Request object created');
        debugPrint('CreateTeamScreen: Request.toJson(): ${createRequest.toJson()}');

        // Отправляем запрос на сервер
        final teamResponse = await teamService.createTeam(createRequest);

        // Создаем TeamData из ответа (для совместимости с UI)
        final teamData = TeamData.fromTeamResponse(teamResponse);

        // Добавляем локальные данные (goal и members), которые не поддерживаются API
        final members = <TeamMember>[];
        for (int i = 0; i < _roleControllers.length; i++) {
          final role = _roleControllers[i].text.trim();
          final nickname = _nicknameControllers[i].text.trim();

          if (role.isNotEmpty && nickname.isNotEmpty) {
            members.add(TeamMember(role: role, nickname: nickname));
          }
        }

        final fullTeamData = TeamData(
          id: teamData.id,
          name: teamData.name,
          description: teamData.description,
          goal: _goalController.text.trim(),
          members: members,
        );

        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Передаем данные обратно
        if (widget.onTeamCreated != null) {
          widget.onTeamCreated!(fullTeamData);
        }

        // Показываем сообщение об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Команда "${fullTeamData.name}" создана!'),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }

        // Очищаем форму
        _formKey.currentState!.reset();
        _teamNameController.clear();
        _descriptionController.clear();
        _goalController.clear();

        // Оставляем одно поле для участника
        while (_roleControllers.length > 1) {
          _removeMemberField(_roleControllers.length - 1);
        }
        _roleControllers[0].clear();
        _nicknameControllers[0].clear();
      } on ApiException catch (e) {
        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Если ошибка авторизации, перенаправляем на экран входа
        if (e.message.contains('Не авторизован') || e.message.contains('401')) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при создании команды: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Создание команды',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Форма
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название команды
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _teamNameController,
                        label: 'Название команды',
                        hint: 'Введите название команды',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название команды';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Описание команды
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Описание команды',
                        hint: 'Введите описание команды',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите описание команды';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Цель проекта
                      _buildTextField(
                        controller: _goalController,
                        label: 'Цель проекта',
                        hint: 'Введите цель проекта',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите цель проекта';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Участники команды
                      Text(
                        'Участники команды',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Список участников
                      ...List.generate(
                        _roleControllers.length,
                        (index) => _buildMemberField(index),
                      ),

                      // Кнопка добавления участника
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addMemberField,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить участника'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Кнопка создания команды
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createTeam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Создать команду',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: TextInputType.text,
          // Убираем inputFormatters - Flutter по умолчанию поддерживает все символы включая русские
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMemberField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Роль',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _roleControllers[index],
                      keyboardType: TextInputType.text,
                      // Убираем inputFormatters - Flutter по умолчанию поддерживает все символы включая русские
                      decoration: InputDecoration(
                        hintText: 'Например: Разработчик',
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Никнейм',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameControllers[index],
                      keyboardType: TextInputType.text,
                      // Убираем inputFormatters - Flutter по умолчанию поддерживает все символы включая русские
                      decoration: InputDecoration(
                        hintText: '@никнейм',
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (_roleControllers.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeMemberField(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  tooltip: 'Удалить участника',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
