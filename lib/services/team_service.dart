import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/public_user.dart';
import '../models/team_invitation.dart';
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

  /// Проверка существования пользователя по email.
  ///
  /// Ожидаемая ручка бэкенда:
  /// GET /api/users/lookup?email={email}
  /// - 200: { id, email, name? }
  /// - 404: пользователь не найден
  Future<PublicUser?> lookupUserByEmail(String email) async {
    try {
      final response = await _apiClient.get(
        '/api/users/lookup',
        queryParameters: {'email': email},
      );
      return PublicUser.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // ApiClient выбросит ApiException('Ресурс не найден.') при 404,
      // в UI это будет показано как "Пользователь не найден".
      debugPrint('TeamService: lookupUserByEmail error: $e');
      rethrow;
    }
  }

  /// Отправить приглашение пользователю вступить в команду.
  ///
  /// Ожидаемая ручка бэкенда:
  /// POST /api/teams/{teamId}/invitations  body: { email, role }
  /// - 200/201: TeamInvitation JSON
  Future<TeamInvitation> inviteUserToTeam({
    required int teamId,
    required String email,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/api/teams/$teamId/invitations',
      body: {'email': email, 'role': role},
    );
    return TeamInvitation.fromJson(response as Map<String, dynamic>);
  }

  /// Получить входящие приглашения (для текущего пользователя).
  ///
  /// Ожидаемая ручка бэкенда:
  /// GET /api/invitations/incoming?status=PENDING
  Future<List<TeamInvitation>> getIncomingInvitations({
    TeamInvitationStatus status = TeamInvitationStatus.pending,
  }) async {
    final response = await _apiClient.get(
      '/api/invitations/incoming',
      queryParameters: {'status': teamInvitationStatusToJson(status)},
    );
    if (response is List) {
      return response
          .map((e) => TeamInvitation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Получить исходящие приглашения по команде (для тимлида/админа).
  ///
  /// Ожидаемая ручка бэкенда:
  /// GET /api/teams/{teamId}/invitations?status=PENDING
  Future<List<TeamInvitation>> getTeamOutgoingInvitations({
    required int teamId,
    TeamInvitationStatus status = TeamInvitationStatus.pending,
  }) async {
    final response = await _apiClient.get(
      '/api/teams/$teamId/invitations',
      queryParameters: {'status': teamInvitationStatusToJson(status)},
    );
    if (response is List) {
      return response
          .map((e) => TeamInvitation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Принять приглашение.
  ///
  /// Ожидаемая ручка бэкенда:
  /// POST /api/invitations/{invitationId}/accept
  Future<void> acceptInvitation(int invitationId) async {
    await _apiClient.post('/api/invitations/$invitationId/accept');
  }

  /// Отклонить приглашение.
  ///
  /// Ожидаемая ручка бэкенда:
  /// POST /api/invitations/{invitationId}/decline
  Future<void> declineInvitation(int invitationId) async {
    await _apiClient.post('/api/invitations/$invitationId/decline');
  }
}

