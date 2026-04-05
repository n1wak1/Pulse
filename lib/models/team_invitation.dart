enum TeamInvitationStatus { pending, accepted, declined, cancelled }

TeamInvitationStatus teamInvitationStatusFromJson(String? value) {
  switch (value) {
    case 'PENDING':
      return TeamInvitationStatus.pending;
    case 'ACCEPTED':
      return TeamInvitationStatus.accepted;
    case 'DECLINED':
      return TeamInvitationStatus.declined;
    case 'CANCELLED':
      return TeamInvitationStatus.cancelled;
    default:
      return TeamInvitationStatus.pending;
  }
}

String teamInvitationStatusToJson(TeamInvitationStatus status) {
  switch (status) {
    case TeamInvitationStatus.pending:
      return 'PENDING';
    case TeamInvitationStatus.accepted:
      return 'ACCEPTED';
    case TeamInvitationStatus.declined:
      return 'DECLINED';
    case TeamInvitationStatus.cancelled:
      return 'CANCELLED';
  }
}

class TeamInvitation {
  final int id;
  final int teamId;
  final String teamName;
  final String inviterName;
  final String inviteeEmail;
  final String? inviteeName;
  final String role;
  final TeamInvitationStatus status;
  final DateTime createdAt;

  TeamInvitation({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.inviterName,
    required this.inviteeEmail,
    required this.inviteeName,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    try {
      createdAt = DateTime.parse((json['createdAt'] as String?) ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    return TeamInvitation(
      id: (json['id'] as int?) ?? 0,
      teamId: (json['teamId'] as int?) ?? 0,
      teamName: (json['teamName'] as String?) ?? '',
      inviterName: (json['inviterName'] as String?) ?? '',
      inviteeEmail: (json['inviteeEmail'] as String?) ?? '',
      inviteeName: (json['inviteeName'] as String?),
      role: (json['role'] as String?) ?? '',
      status: teamInvitationStatusFromJson(json['status'] as String?),
      createdAt: createdAt,
    );
  }
}

