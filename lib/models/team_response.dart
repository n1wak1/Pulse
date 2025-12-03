/// Модель ответа API для команды (TeamResponse из swagger)
class TeamResponse {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  TeamResponse({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Конструктор из JSON
  factory TeamResponse.fromJson(Map<String, dynamic> json) {
    return TeamResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Модель запроса на создание команды (CreateTeamRequest из swagger)
class CreateTeamRequest {
  final String name;
  final String? description;

  CreateTeamRequest({
    required this.name,
    this.description,
  });

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    return json;
  }
}



