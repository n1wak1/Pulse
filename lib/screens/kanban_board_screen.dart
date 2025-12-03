import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/kanban_column.dart';
import '../models/user_role.dart';
import '../widgets/task_card.dart';
import '../services/api_service.dart';

class KanbanBoardScreen extends StatefulWidget {
  final Function(VoidCallback)? onAddTaskCallback;

  const KanbanBoardScreen({super.key, this.onAddTaskCallback});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  List<Task> _tasks = [];
  List<KanbanColumn> _columns = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  UserRole _userRole = UserRole.developer; // По умолчанию

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _loadTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAddTaskCallback?.call(showAddTaskDialog);
    });
  }

  void _initializeColumns() {
    // Стандартные колонки по умолчанию
    setState(() {
      _columns = [
        KanbanColumn(
          id: '1',
          name: 'Backlog',
          status: TaskStatus.backlog,
          order: 0,
        ),
        KanbanColumn(
          id: '2',
          name: 'In Progress',
          status: TaskStatus.inProgress,
          order: 1,
        ),
        KanbanColumn(
          id: '3',
          name: 'Review',
          status: TaskStatus.review,
          order: 2,
        ),
        KanbanColumn(
          id: '4',
          name: 'Done',
          status: TaskStatus.done,
          order: 3,
        ),
      ];
    });
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tasks = await _apiService.getAllTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки задач: $e')),
        );
      }
    }
  }

  List<Task> _getTasksForColumn(KanbanColumn column) {
    if (column.status != null) {
      return _tasks.where((task) => task.status == column.status).toList();
    }
    // Если колонка без статуса, можно добавить свою логику
    return [];
  }

  void _deleteTask(Task task) async {
    try {
      await _apiService.deleteTask(task.id);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления задачи: $e')),
        );
      }
    }
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        task: task,
        onSave: (title, description, status, projectId) async {
          try {
            final updatedTask = await _apiService.updateTask(
              task.id,
              {
                'title': title,
                'description': description.isEmpty ? null : description,
                'status': status.toBackendString(),
                if (projectId != null) 'projectId': projectId,
              },
            );
            setState(() {
              final index = _tasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _tasks[index] = updatedTask;
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Задача обновлена')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка обновления задачи: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _onTaskTap(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFfafafa),
        title: Text(
          task.title,
          style: const TextStyle(color: Color(0xFF000000)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) ...[
                Text(
                  task.description!,
                  style: const TextStyle(color: Color(0xFF000000), fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(task.status.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_canDeleteTask()) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(task);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
          if (_canEditTask()) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editTask(task);
              },
              child: const Text(
                'Редактировать',
                style: TextStyle(color: Color(0xFF636363)),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Color(0xFF636363)),
            ),
          ),
        ],
      ),
    );
  }

  bool _canEditTask() {
    return _userRole == UserRole.admin ||
        _userRole == UserRole.manager ||
        _userRole == UserRole.developer;
  }

  bool _canDeleteTask() {
    return _userRole == UserRole.admin || _userRole == UserRole.manager;
  }

  bool _canCreateColumn() {
    return _userRole == UserRole.admin || _userRole == UserRole.manager;
  }

  void showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        onSave: (title, description, status, projectId) async {
          try {
            final newTask = await _apiService.createTask({
              'title': title,
              'description': description.isEmpty ? null : description,
              'status': status.toBackendString(),
              if (projectId != null) 'projectId': projectId,
            });
            setState(() {
              _tasks.add(newTask);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Задача создана')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка создания задачи: $e')),
              );
            }
          }
        },
        task: null,
      ),
    );
  }

  void _addColumn() {
    if (!_canCreateColumn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет прав для создания колонок')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddColumnDialog(
        onSave: (name) {
          setState(() {
            _columns.add(
              KanbanColumn(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                order: _columns.length,
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFfafafa),
      child: Column(
        children: [
          // Кнопка добавления колонки
          if (_canCreateColumn())
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addColumn,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить колонку'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF636363),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          // Канбан доска
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    itemCount: _columns.length,
                    itemBuilder: (context, index) {
                      final column = _columns[index];
                      final columnTasks = _getTasksForColumn(column);
                      return _KanbanColumnWidget(
                        column: column,
                        tasks: columnTasks,
                        onTaskTap: _onTaskTap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const _KanbanColumnWidget({
    required this.column,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  column.name,
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF636363),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'Нет задач',
                        style: TextStyle(
                          color: const Color(0xFF000000).withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => onTaskTap(task),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  final Function(String title, String description, TaskStatus status, int? projectId) onSave;
  final Task? task;

  const _AddTaskDialog({required this.onSave, this.task});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedStatus = widget.task?.status ?? TaskStatus.backlog;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedStatus,
      null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFfafafa),
      title: Text(
        widget.task == null ? 'Новая задача' : 'Редактировать задачу',
        style: const TextStyle(color: Color(0xFF000000)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название задачи',
                labelStyle: TextStyle(color: Color(0xFF000000)),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Color(0xFF000000)),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                labelStyle: TextStyle(color: Color(0xFF000000)),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Color(0xFF000000)),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                labelStyle: TextStyle(color: Color(0xFF000000)),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFFfafafa),
              style: const TextStyle(color: Color(0xFF000000)),
              items: TaskStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Отмена',
            style: TextStyle(color: Color(0xFF636363)),
          ),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF636363),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.task == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }
}

class _AddColumnDialog extends StatefulWidget {
  final Function(String name) onSave;

  const _AddColumnDialog({required this.onSave});

  @override
  State<_AddColumnDialog> createState() => _AddColumnDialogState();
}

class _AddColumnDialogState extends State<_AddColumnDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveColumn() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название колонки')),
      );
      return;
    }

    widget.onSave(_nameController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFfafafa),
      title: const Text(
        'Новая колонка',
        style: TextStyle(color: Color(0xFF000000)),
      ),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Название колонки',
          labelStyle: TextStyle(color: Color(0xFF000000)),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(color: Color(0xFF000000)),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Отмена',
            style: TextStyle(color: Color(0xFF636363)),
          ),
        ),
        ElevatedButton(
          onPressed: _saveColumn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF636363),
            foregroundColor: Colors.white,
          ),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
