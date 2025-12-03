import 'task.dart';

class KanbanColumn {
  final String id;
  final String name;
  final TaskStatus? status;
  final int order;
  final String? color;

  KanbanColumn({
    required this.id,
    required this.name,
    this.status,
    required this.order,
    this.color,
  });

  KanbanColumn copyWith({
    String? id,
    String? name,
    TaskStatus? status,
    int? order,
    String? color,
  }) {
    return KanbanColumn(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      order: order ?? this.order,
      color: color ?? this.color,
    );
  }
}

