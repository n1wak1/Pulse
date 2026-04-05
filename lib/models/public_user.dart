class PublicUser {
  final int id;
  final String email;
  final String? name;

  PublicUser({required this.id, required this.email, this.name});

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: (json['id'] as int?) ?? 0,
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? (json['displayName'] as String?),
    );
  }
}

