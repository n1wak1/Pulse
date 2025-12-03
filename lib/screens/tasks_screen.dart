import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  final Function(VoidCallback)? onAddTaskCallback;

  const TasksScreen({super.key, this.onAddTaskCallback});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  TaskStatus? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Передаем коллбэк родителю
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAddTaskCallback?.call(_addNewTask);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _deleteTask(Task task) async {
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

  List<Task> get _filteredTasks {
    var filtered = _tasks;

    // Фильтрация по статусу
    if (_selectedFilter != null) {
      filtered = filtered
          .where((task) => task.status == _selectedFilter)
          .toList();
    }

    // Поиск по тексту
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final titleMatch = task.title.toLowerCase().contains(_searchQuery);
        final descriptionMatch =
            task.description?.toLowerCase().contains(_searchQuery) ?? false;
        return titleMatch || descriptionMatch;
      }).toList();
    }

    return filtered;
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
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF636363),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTask(task);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
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

  void _addNewTask() {
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
      ),
    );
  }

  void _onFilterChanged(TaskStatus? status) {
    setState(() {
      _selectedFilter = status;
    });
  }

  void showAddTaskDialog() {
    _addNewTask();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    return Container(
      color: const Color(0xFFfafafa),
      child: Column(
        children: [
          // Поиск
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск задач...',
                hintStyle: TextStyle(
                  color: const Color(0xFF000000).withOpacity(0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF636363)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Color(0xFF000000)),
            ),
          ),

          // Фильтры
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Все',
                  isSelected: _selectedFilter == null,
                  onSelected: () => _onFilterChanged(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: TaskStatus.backlog.label,
                  isSelected: _selectedFilter == TaskStatus.backlog,
                  onSelected: () => _onFilterChanged(TaskStatus.backlog),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: TaskStatus.inProgress.label,
                  isSelected: _selectedFilter == TaskStatus.inProgress,
                  onSelected: () => _onFilterChanged(TaskStatus.inProgress),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: TaskStatus.review.label,
                  isSelected: _selectedFilter == TaskStatus.review,
                  onSelected: () => _onFilterChanged(TaskStatus.review),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: TaskStatus.done.label,
                  isSelected: _selectedFilter == TaskStatus.done,
                  onSelected: () => _onFilterChanged(TaskStatus.done),
                ),
              ],
            ),
          ),

          // Список задач
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: const Color(0xFF000000).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Задач не найдено',
                          style: TextStyle(
                            color: const Color(0xFF000000).withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () => _onTaskTap(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF636363),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF000000),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF636363) : Colors.grey.shade300,
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
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название задачи')));
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedStatus,
      null, // projectId - пока null
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363), width: 2),
                ),
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363), width: 2),
                ),
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF636363), width: 2),
                ),
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
