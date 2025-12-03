class Task {
  final String id;
  final String title;
  final DateTime deadline;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
  });
}
