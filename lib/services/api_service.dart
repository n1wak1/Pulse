import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../core/api_client.dart';

class ApiService {
  final ApiClient _apiClient;

  ApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Задачи
  Future<List<Task>> getAllTasks() async {
    try {
      final response = await _apiClient.get('/api/tasks');
      if (response is List) {
        return (response as List)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }

  Future<List<Task>> getTeamTasks(int teamId) async {
    try {
      final response = await _apiClient.post(
        '/api/tasks/by-team',
        body: {'teamId': teamId},
      );
      if (response is List) {
        return (response as List)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching team tasks: $e');
      rethrow;
    }
  }

  Future<Task> getTask(int id) async {
    try {
      final response = await _apiClient.get('/api/tasks/$id');
      return Task.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching task: $e');
      rethrow;
    }
  }

  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _apiClient.post('/api/tasks', body: taskData);
      return Task.fromJson(response);
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  Future<Task> updateTask(int id, Map<String, dynamic> taskData) async {
    try {
      final response = await _apiClient.put('/api/tasks/$id', body: taskData);
      return Task.fromJson(response);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _apiClient.delete('/api/tasks/$id');
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<List<Task>> getTasksByStatus(String status) async {
    try {
      final response = await _apiClient.get('/api/tasks/status/$status');
      if (response is List) {
        return (response)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tasks by status: $e');
      rethrow;
    }
  }

  Future<List<Task>> getTasksAssignedToMe() async {
    try {
      final response = await _apiClient.get('/api/tasks/assigned-to-me');
      if (response is List) {
        return (response)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching assigned tasks: $e');
      rethrow;
    }
  }
}
