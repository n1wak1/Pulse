import 'package:flutter/foundation.dart';
import 'team_member_api.dart';
import 'team_participant.dart';

/// Модель ответа API для команды (TeamResponse из swagger)
class TeamResponse {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<TeamMemberApi> members;
  final List<TeamParticipant> participants;

  TeamResponse({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.members = const [],
    this.participants = const [],
  });

  /// Конструктор из JSON
  factory TeamResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('TeamResponse.fromJson: Parsing team ${json['id']}');
    debugPrint('TeamResponse.fromJson: JSON keys: ${json.keys.toList()}');
    debugPrint('TeamResponse.fromJson: members value: ${json['members']}');
    debugPrint('TeamResponse.fromJson: participants value: ${json['participants']}');
    
    final members = json['members'] != null
        ? (json['members'] as List)
            .map((m) {
              try {
                debugPrint('TeamResponse.fromJson: Parsing member: $m');
                if (m == null) {
                  debugPrint('TeamResponse.fromJson: WARNING - member is null, skipping');
                  return null;
                }
                return TeamMemberApi.fromJson(m as Map<String, dynamic>);
              } catch (e) {
                debugPrint('TeamResponse.fromJson: Error parsing member $m: $e');
                return null;
              }
            })
            .whereType<TeamMemberApi>()
            .toList()
        : <TeamMemberApi>[];
    
    final participants = json['participants'] != null
        ? (json['participants'] as List)
            .map((p) {
              try {
                debugPrint('TeamResponse.fromJson: Parsing participant: $p');
                if (p == null) {
                  debugPrint('TeamResponse.fromJson: WARNING - participant is null, skipping');
                  return null;
                }
                return TeamParticipant.fromJson(p as Map<String, dynamic>);
              } catch (e) {
                debugPrint('TeamResponse.fromJson: Error parsing participant $p: $e');
                return null;
              }
            })
            .whereType<TeamParticipant>()
            .toList()
        : <TeamParticipant>[];
    
    debugPrint('TeamResponse.fromJson: Parsed ${members.length} members and ${participants.length} participants');
    
    // Безопасный парсинг даты
    DateTime createdAt;
    try {
      final createdAtStr = json['createdAt'] as String?;
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr);
      } else {
        debugPrint('TeamResponse.fromJson: createdAt is null or empty, using current time');
        createdAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('TeamResponse.fromJson: Error parsing createdAt: $e');
      createdAt = DateTime.now();
    }
    
    // Безопасный парсинг имени
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      debugPrint('TeamResponse.fromJson: WARNING - name is null or empty, using empty string');
      // Используем пустую строку вместо исключения, чтобы не ломать приложение
    }
    
    return TeamResponse(
      id: json['id'] as int? ?? 0,
      name: name ?? '',
      description: json['description'] as String?,
      createdAt: createdAt,
      members: members,
      participants: participants,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

/// Модель запроса на создание команды (CreateTeamRequest из swagger)
class CreateTeamRequest {
  final String name;
  final String? description;
  final List<Map<String, String>>? participants;

  CreateTeamRequest({
    required this.name,
    this.description,
    this.participants,
  });

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (participants != null && participants!.isNotEmpty) {
      json['participants'] = participants;
    }
    return json;
  }
}



