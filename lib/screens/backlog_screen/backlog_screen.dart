import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../notifiers/current_project_notifier.dart';
import '../../services/api_service.dart';
import '../../widgets/exception_widget.dart';
import '../../widgets/task_card.dart';
import '../login_screen.dart';
import '../task_detail_screen.dart';
import 'cubit/backlog_cubit.dart';

class BacklogScreen extends StatelessWidget {
  const BacklogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BacklogCubit(
        ApiService(),
        Provider.of<CurrentProjectNotifier>(context, listen: false),
      ),
      child: const BacklogView(),
    );
  }
}

class BacklogView extends StatefulWidget {
  const BacklogView({super.key});

  @override
  State<BacklogView> createState() => _BacklogViewState();
}

class _BacklogViewState extends State<BacklogView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<BacklogCubit>().search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTaskDetail(Task task) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );

    if (result != null && mounted) {
      context.read<BacklogCubit>().loadTasks();
    }
  }

  Future<void> _openCreateTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const TaskDetailScreen()),
    );

    if (result != null && mounted) {
      context.read<BacklogCubit>().loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<BacklogCubit, BacklogState>(
        listener: (context, state) {
          if (state is BacklogError) {
            if (state.isUnauthorized) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск задач...',
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF636363),
                    ),
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

              // Task List
              Expanded(
                child: switch (state) {
                  BacklogInitial() || BacklogLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  BacklogLoaded(filteredTasks: var filteredTasks) =>
                    filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Задач не найдено',
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async =>
                                context.read<BacklogCubit>().loadTasks(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return TaskCard(
                                  task: task,
                                  onTap: () => _openTaskDetail(task),
                                );
                              },
                            ),
                          ),
                  BacklogError(message: var message) => ExceptionWidget(
                    title: 'Не удалось загрузить задачи',
                    message: message,
                    onRestart: () => context.read<BacklogCubit>().loadTasks(),
                  ),
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTask,
        backgroundColor: const Color(0xFF636363),
        tooltip: 'Добавить задачу',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
