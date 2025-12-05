import 'package:flutter/material.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final int? assigneeId;
  final String? assigneeName;
  final int? projectId;
  final int? sprintId;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.assigneeId,
    this.assigneeName,
    this.projectId,
    this.sprintId,
    this.deadline,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskStatus? status,
    int? assigneeId,
    String? assigneeName,
    int? projectId,
    int? sprintId,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      projectId: projectId ?? this.projectId,
      sprintId: sprintId ?? this.sprintId,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Методы для конвертации в/из JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromBackendString(json['status'] as String),
      assigneeId: json['assigneeId'] as int?,
      assigneeName: json['assigneeName'] as String?,
      projectId: json['projectId'] as int?,
      sprintId: json['sprintId'] as int?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toBackendString(),
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'projectId': projectId,
      'sprintId': sprintId,
      'deadline': deadline?.toIso8601String().split('T')[0],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'status': status.toBackendString(),
      if (projectId != null) 'projectId': projectId,
      if (sprintId != null) 'sprintId': sprintId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (deadline != null)
        'deadline': deadline!.toIso8601String().split('T')[0],
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'status': status.toBackendString(),
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (sprintId != null) 'sprintId': sprintId,
      if (deadline != null)
        'deadline': deadline!.toIso8601String().split('T')[0],
    };
  }
}

enum TaskStatus {
  backlog('Бэклог', 'BACKLOG'),
  inProgress('В работе', 'IN_PROGRESS'),
  review('На проверке', 'REVIEW'),
  done('Готово', 'DONE');

  const TaskStatus(this.label, this.backendValue);
  final String label;
  final String backendValue;

  // Маппинг из бекенда
  static TaskStatus fromBackendString(String value) {
    switch (value) {
      case 'BACKLOG':
        return TaskStatus.backlog;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'REVIEW':
        return TaskStatus.review;
      case 'DONE':
        return TaskStatus.done;
      default:
        return TaskStatus.backlog;
    }
  }

  // Маппинг в бекенд
  String toBackendString() => backendValue;

  // Цвет для статуса
  Color get colorValue {
    switch (this) {
      case TaskStatus.backlog:
        return const Color.fromARGB(255, 223, 223, 223); // Красный
      case TaskStatus.inProgress:
        return const Color.fromARGB(255, 151, 208, 255); // Оранжевый
      case TaskStatus.review:
        return const Color.fromARGB(255, 209, 186, 248); // Синий
      case TaskStatus.done:
        return Color.fromARGB(255, 186, 255, 171); // Зеленый
    }
  }
}
