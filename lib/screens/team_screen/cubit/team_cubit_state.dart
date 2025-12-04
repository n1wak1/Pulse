part of 'team_cubit_cubit.dart';

@immutable
class TeamState {
  final bool isLoading;
  final List<TeamResponse> teams;
  final TeamResponse? currentTeam;
  final String? error;

  const TeamState({
    this.isLoading = false,
    this.teams = const [],
    this.currentTeam,
    this.error,
  });

  TeamState copyWith({
    bool? isLoading,
    List<TeamResponse>? teams,
    TeamResponse? currentTeam,
    String? error,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      teams: teams ?? this.teams,
      currentTeam: currentTeam ?? this.currentTeam,
      error: error ?? this.error,
    );
  }
}
