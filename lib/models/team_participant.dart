/// Модель текстового участника команды (participants из API)
class TeamParticipant {
  final int id;
  final String name;
  final String role;

  TeamParticipant({
    required this.id,
    required this.name,
    required this.role,
  });

  factory TeamParticipant.fromJson(Map<String, dynamic> json) {
    return TeamParticipant(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}

