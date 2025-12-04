import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../models/task.dart';
import '../models/team_data.dart';
import '../services/api_service.dart';
import '../services/team_service.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import 'create_team_screen.dart';
import 'task_detail_screen.dart';
import 'login_screen.dart';
import '../widgets/task_card.dart';

class TeamScreen extends StatefulWidget {
  final TeamData? teamData;
  final Function(TeamData)? onTeamCreated;

  const TeamScreen({super.key, this.teamData, this.onTeamCreated});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  // Цвета
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);
  static const Color accentColor = Color(0xFF73A168);
  static const Color textColor = Color(0xFF000000);
  static const Color dividerColor = Color(0xFF636363);

  // Состояние
  bool _isLoading = false;
  List<TeamMember> _teamMembers = [];
  List<Task> _tasks = [];
  String _teamName = 'Название команды';
  final ApiService _apiService = ApiService();
  final TeamService _teamService = TeamService(ApiClient());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(TeamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.teamData != oldWidget.teamData) {
      _updateDataFromTeamData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем задачи, назначенные на текущего пользователя
      final assignedTasks = await _apiService.getTasksAssignedToMe();

      // Загружаем данные команды
      if (widget.teamData != null) {
        _teamName = widget.teamData!.name;
        _teamMembers = widget.teamData!.members;
      } else {
        // Загружаем команды пользователя через API
        try {
          final teams = await _teamService.getAllTeams();
          if (teams.isNotEmpty) {
            final team = teams.first;
            _teamName = team.name;
            // Преобразуем TeamMemberApi в TeamMember для UI
            _teamMembers = team.members.map((m) => 
              TeamMember(role: m.role, nickname: m.userName)
            ).toList();
          } else {
            _teamName = 'Моя команда';
            _teamMembers = [];
          }
        } catch (e) {
          // Если не удалось загрузить команды, используем значения по умолчанию
          _teamName = 'Моя команда';
          _teamMembers = [];
        }
      }

      if (mounted) {
        setState(() {
          _tasks = assignedTasks;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Если ошибка авторизации, перенаправляем на экран входа
        if (e.message.contains('Не авторизован') || e.message.contains('401')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
        // Используем переданные данные команды при ошибке загрузки задач
        if (widget.teamData != null) {
          _teamName = widget.teamData!.name;
          _teamMembers = widget.teamData!.members;
        } else {
          _teamName = 'Моя команда';
          _teamMembers = [];
        }
        _tasks = [];
        
        // Показываем ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Используем переданные данные команды при ошибке загрузки задач
        if (widget.teamData != null) {
          _teamName = widget.teamData!.name;
          _teamMembers = widget.teamData!.members;
        } else {
          _teamName = 'Моя команда';
          _teamMembers = [];
        }
        _tasks = [];
        
        // Показываем ошибку только если есть задачи, чтобы не пугать пользователя при первом запуске
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _updateDataFromTeamData() {
    if (widget.teamData != null) {
      setState(() {
        _teamName = widget.teamData!.name;
        _teamMembers = widget.teamData!.members;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Загрузка...',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Верхняя панель с заголовком
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // Список участников команды
        SliverToBoxAdapter(
          child: _buildTeamMembersSection(),
        ),
        // Разделительная линия
        SliverToBoxAdapter(
          child: _buildDivider(),
        ),
        // Список задач
        _buildTasksSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _teamName,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final result = await Navigator.push<TeamData>(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTeamScreen(
                    onTeamCreated: (teamData) {
                      Navigator.of(context).pop(teamData);
                    },
                  ),
                ),
              );
              if (result != null && mounted) {
                widget.onTeamCreated?.call(result);
                setState(() {
                  _teamName = result.name;
                  _teamMembers = result.members;
                });
              }
            },
            tooltip: 'Создать команду',
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection() {
    if (_teamMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            _teamMembers.length,
            (index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildTeamMemberCard(_teamMembers[index]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.role,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.nickname,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 1,
      color: dividerColor,
    );
  }

  Widget _buildTasksSection() {
    if (_tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: TaskCard(
              task: _tasks[index],
              onTap: () async {
                final result = await Navigator.push<Task>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: _tasks[index]),
                  ),
                );
                if (result != null && mounted) {
                  _loadData(); // Обновляем список после редактирования
                }
              },
            ),
          );
        },
        childCount: _tasks.length,
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Нет задач',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первую задачу',
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
