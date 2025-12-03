import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_card.dart';

class TaskColumn extends StatelessWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final Function(Task)? onTaskTap;
  final Function(Task, TaskStatus)? onStatusChanged;

  const TaskColumn({
    super.key,
    required this.status,
    required this.tasks,
    this.onTaskTap,
    this.onStatusChanged,
  });

  int get taskCount => tasks.length;

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
                  status.label,
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
                    '$taskCount',
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
                          onTap: () => onTaskTap?.call(task),
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

