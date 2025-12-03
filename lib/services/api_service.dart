import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
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
      print('Error fetching tasks: $e');
      rethrow;
    }
  }

  Future<Task> getTask(int id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching task: $e');
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
      print('Error creating task: $e');
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
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } catch (e) {
      print('Error deleting task: $e');
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
      print('Error fetching tasks by status: $e');
      rethrow;
    }
  }
}

