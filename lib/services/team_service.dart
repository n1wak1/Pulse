import '../core/api_client.dart';
import '../models/team_response.dart';

/// Сервис для работы с API команд
class TeamService {
  final ApiClient _apiClient;

  TeamService(this._apiClient);

  /// Получить все команды
  Future<List<TeamResponse>> getAllTeams() async {
    try {
      final response = await _apiClient.get('/api/teams');
      
      // API возвращает массив напрямую
      if (response is List) {
        return response
            .map((team) => TeamResponse.fromJson(team as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Ошибка при получении команд: $e');
    }
  }

  /// Получить команду по ID
  Future<TeamResponse> getTeam(int teamId) async {
    try {
      final response = await _apiClient.get('/api/teams/$teamId');
      return TeamResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка при получении команды: $e');
    }
  }

  /// Создать новую команду
  Future<TeamResponse> createTeam(CreateTeamRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/teams',
        body: request.toJson(),
      );
      return TeamResponse.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка при создании команды: $e');
    }
  }
}

