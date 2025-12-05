import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      
      debugPrint('TeamService: getAllTeams response type: ${response.runtimeType}');
      
      // API возвращает массив напрямую
      if (response is List) {
        debugPrint('TeamService: Got ${response.length} teams');
        final teams = response
            .map((team) {
              debugPrint('TeamService: Team JSON: $team');
              return TeamResponse.fromJson(team as Map<String, dynamic>);
            })
            .toList();
        
        // Логируем каждую команду
        for (final team in teams) {
          debugPrint('TeamService: Team ${team.id} "${team.name}"');
          debugPrint('TeamService:   - members: ${team.members.length}');
          debugPrint('TeamService:   - participants: ${team.participants.length}');
          for (final member in team.members) {
            debugPrint('TeamService:     Member: ${member.userName} (${member.role})');
          }
          for (final participant in team.participants) {
            debugPrint('TeamService:     Participant: ${participant.name} (${participant.role})');
          }
        }
        
        return teams;
      }
      
      return [];
    } catch (e) {
      debugPrint('TeamService: Error getting teams: $e');
      throw Exception('Ошибка при получении команд: $e');
    }
  }

  /// Получить команду по ID
  Future<TeamResponse> getTeam(int teamId) async {
    try {
      final response = await _apiClient.get('/api/teams/$teamId');
      debugPrint('TeamService: getTeam($teamId) response: $response');
      final team = TeamResponse.fromJson(response as Map<String, dynamic>);
      debugPrint('TeamService: Parsed team: ${team.name}');
      debugPrint('TeamService:   - members: ${team.members.length}');
      debugPrint('TeamService:   - participants: ${team.participants.length}');
      return team;
    } catch (e) {
      debugPrint('TeamService: Error getting team $teamId: $e');
      throw Exception('Ошибка при получении команды: $e');
    }
  }

  /// Создать новую команду
  Future<TeamResponse> createTeam(CreateTeamRequest request) async {
    try {
      final requestBody = request.toJson();
      debugPrint('TeamService: Creating team');
      debugPrint('TeamService: Request body: $requestBody');
      debugPrint('TeamService: Request JSON: ${jsonEncode(requestBody)}');
      
      final response = await _apiClient.post(
        '/api/teams',
        body: requestBody,
      );
      
      debugPrint('TeamService: Response received: $response');
      return TeamResponse.fromJson(response);
    } catch (e) {
      debugPrint('TeamService: Error creating team: $e');
      throw Exception('Ошибка при создании команды: $e');
    }
  }
}

