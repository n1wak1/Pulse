import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../models/task.dart';
import '../models/team_data.dart';

class TeamScreen extends StatefulWidget {
  final TeamData? teamData;

  const TeamScreen({super.key, this.teamData});

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

    // Имитация загрузки данных
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      if (widget.teamData != null) {
        // Используем данные из экрана создания команды
        _teamName = widget.teamData!.name;
        _teamMembers = widget.teamData!.members;
      } else {
        // ФЕЙКОВЫЕ ДАННЫЕ - редактируйте здесь
        _teamName = 'Название команды';
        
        _teamMembers = [
          TeamMember(role: 'Руководитель', nickname: '@alex_dev'),
          TeamMember(role: 'Разработчик', nickname: '@maria_code'),
          TeamMember(role: 'Дизайнер', nickname: '@ivan_design'),
          TeamMember(role: 'Тестировщик', nickname: '@anna_test'),
        ];
      }

      // Задачи всегда фейковые (можно будет добавить позже)
      _tasks = [
        Task(
          id: '1',
          title: 'Реализовать авторизацию',
          deadline: DateTime.now().add(const Duration(days: 3)),
        ),
        Task(
          id: '2',
          title: 'Создать главный экран',
          deadline: DateTime.now().add(const Duration(days: 5)),
        ),
        Task(
          id: '3',
          title: 'Написать тесты',
          deadline: DateTime.now().add(const Duration(days: 7)),
        ),
      ];

      _isLoading = false;
    });
  }

  void _updateDataFromTeamData() {
    if (widget.teamData != null) {
      setState(() {
        _teamName = widget.teamData!.name;
        _teamMembers = widget.teamData!.members;
      });
    }
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inDays < 0) {
      return 'Просрочено';
    } else if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Завтра';
    } else {
      return 'Через ${difference.inDays} дн.';
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
      child: Text(
        _teamName,
        style: TextStyle(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
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
            child: Dismissible(
              key: Key(_tasks[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              onDismissed: (direction) {
                _deleteTask(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Задача "${_tasks[index].title}" удалена'),
                    backgroundColor: accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              child: _buildTaskCard(_tasks[index], index),
            ),
          );
        },
        childCount: _tasks.length,
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    final isOverdue = task.deadline.isBefore(DateTime.now()) && !task.isCompleted;
    final deadlineText = _formatDeadline(task.deadline);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
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
          GestureDetector(
            onTap: () => _toggleTaskCompletion(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted ? accentColor : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? accentColor : dividerColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted
                        ? textColor.withOpacity(0.5)
                        : textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue
                          ? Colors.red
                          : textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      deadlineText,
                      style: TextStyle(
                        color: isOverdue
                            ? Colors.red
                            : textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
