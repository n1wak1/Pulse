import 'team_member.dart';
import 'team_response.dart';

/// Модель данных команды для UI (совместима с TeamResponse)
class TeamData {
  final int? id;
  final String name;
  final String description;
  final String goal;
  final List<TeamMember> members;

  TeamData({
    this.id,
    required this.name,
    required this.description,
    required this.goal,
    required this.members,
  });

  /// Создать из TeamResponse (для работы с API)
  factory TeamData.fromTeamResponse(TeamResponse teamResponse) {
    return TeamData(
      id: teamResponse.id,
      name: teamResponse.name,
      description: teamResponse.description ?? '',
      goal: '', // API не возвращает goal, оставляем пустым
      members: teamResponse.members.map((m) => 
        TeamMember(role: m.role, nickname: m.userName)
      ).toList(),
    );
  }

  /// Преобразовать в TeamResponse для отправки на сервер
  TeamResponse toTeamResponse() {
    // Для создания команды используем только name и description
    // goal и members не поддерживаются API
    return TeamResponse(
      id: id ?? 0,
      name: name,
      description: description.isNotEmpty ? description : null,
      createdAt: DateTime.now(),
    );
  }
}
