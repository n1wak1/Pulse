part of 'team_cubit_cubit.dart';

@immutable
class TeamState {
  final bool isLoading;
  final List<TeamResponse> teams;
  final TeamResponse? currentTeam;
  final String? error;
  final bool isInvitesLoading;
  final List<TeamInvitation> incomingInvites;
  final List<TeamInvitation> outgoingInvites;
  final String? inviteActionError;

  const TeamState({
    this.isLoading = false,
    this.teams = const [],
    this.currentTeam,
    this.error,
    this.isInvitesLoading = false,
    this.incomingInvites = const [],
    this.outgoingInvites = const [],
    this.inviteActionError,
  });

  TeamState copyWith({
    bool? isLoading,
    List<TeamResponse>? teams,
    TeamResponse? currentTeam,
    String? error,
    bool? isInvitesLoading,
    List<TeamInvitation>? incomingInvites,
    List<TeamInvitation>? outgoingInvites,
    String? inviteActionError,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      teams: teams ?? this.teams,
      currentTeam: currentTeam ?? this.currentTeam,
      error: error ?? this.error,
      isInvitesLoading: isInvitesLoading ?? this.isInvitesLoading,
      incomingInvites: incomingInvites ?? this.incomingInvites,
      outgoingInvites: outgoingInvites ?? this.outgoingInvites,
      inviteActionError: inviteActionError,
    );
  }
}
