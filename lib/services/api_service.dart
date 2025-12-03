import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../config/api_config.dart';

class ApiService {
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _authToken ?? ApiConfig.getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        // Не пробрасываем ошибку дальше, чтобы приложение не крашилось
        // если сервер недоступен
        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Задачи
  Future<List<Task>> getAllTasks() async {
    try {
      final response = await _dio.get('/api/tasks');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      // Возвращаем пустой список вместо rethrow, чтобы приложение не крашилось
      return [];
    }
  }

  Future<Task> getTask(int id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching task: $e');
      rethrow;
    }
  }

  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post(
        '/api/tasks',
        data: taskData,
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  Future<Task> updateTask(int id, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.put(
        '/api/tasks/$id',
        data: taskData,
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<List<Task>> getTasksByStatus(String status) async {
    try {
      final response = await _dio.get('/api/tasks/status/$status');
      if (response.data is List) {
        return (response.data as List)
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
      final response = await _dio.get('/api/tasks/assigned-to-me');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching assigned tasks: $e');
      return [];
    }
  }
}

