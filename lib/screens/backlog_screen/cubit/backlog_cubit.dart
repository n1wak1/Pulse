import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../core/api_exception.dart';
import '../../../models/task.dart';
import '../../../notifiers/current_project_notifier.dart';
import '../../../services/api_service.dart';

part 'backlog_state.dart';

class BacklogCubit extends Cubit<BacklogState> {
  final ApiService _apiService;
  final CurrentProjectNotifier _currentProjectNotifier;

  BacklogCubit(this._apiService, this._currentProjectNotifier)
      : super(BacklogInitial()) {
    _currentProjectNotifier.addListener(loadTasks);
    loadTasks();
  }

  void loadTasks() async {
    if (state is! BacklogLoading) {
      emit(BacklogLoading());
    }

    try {
      final team = _currentProjectNotifier.currentProject;
      final tasks = team != null
          ? await _apiService.getTeamTasks(team.id)
          : await _apiService.getAllTasks();
      emit(BacklogLoaded(tasks));
    } on ApiException catch (e) {
      final isUnauthorized =
          e.message.contains('Не авторизован') || e.message.contains('401');
      emit(BacklogError(e.message, isUnauthorized: isUnauthorized));
    } catch (e) {
      emit(BacklogError('Ошибка загрузки задач: $e'));
    }
  }

  void search(String query) {
    if (state is BacklogLoaded) {
      final loadedState = state as BacklogLoaded;
      if (query.isEmpty) {
        emit(loadedState.copyWith(filteredTasks: loadedState.tasks));
      } else {
        final filtered = loadedState.tasks.where((task) {
          final titleMatch = task.title.toLowerCase().contains(query.toLowerCase());
          final descriptionMatch =
              task.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return titleMatch || descriptionMatch;
        }).toList();
        emit(loadedState.copyWith(filteredTasks: filtered));
      }
    }
  }

  @override
  Future<void> close() {
    _currentProjectNotifier.removeListener(loadTasks);
    return super.close();
  }
}

