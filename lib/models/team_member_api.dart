/// Модель участника команды из API
class TeamMemberApi {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String role; // ADMIN, MANAGER, DEVELOPER, DESIGNER, QA

  TeamMemberApi({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
  });

  factory TeamMemberApi.fromJson(Map<String, dynamic> json) {
    return TeamMemberApi(
      id: (json['id'] as int?) ?? 0,
      userId: (json['userId'] as int?) ?? 0,
      userName: (json['userName'] as String?) ?? '',
      userEmail: (json['userEmail'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role,
    };
  }
}

