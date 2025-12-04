part of 'backlog_cubit.dart';

@immutable
sealed class BacklogState {}

final class BacklogInitial extends BacklogState {}

final class BacklogLoading extends BacklogState {}

final class BacklogLoaded extends BacklogState {
  final List<Task> tasks;
  final List<Task> filteredTasks;

  BacklogLoaded(this.tasks, {List<Task>? filteredTasks})
      : filteredTasks = filteredTasks ?? tasks;

  BacklogLoaded copyWith({
    List<Task>? tasks,
    List<Task>? filteredTasks,
  }) {
    return BacklogLoaded(
      tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
    );
  }
}

final class BacklogError extends BacklogState {
  final String message;
  final bool isUnauthorized;

  BacklogError(this.message, {this.isUnauthorized = false});
}
