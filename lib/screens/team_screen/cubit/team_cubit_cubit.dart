import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../models/team_response.dart';
import '../../../services/team_service.dart';

part 'team_cubit_state.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamService _teamService;

  TeamCubit(this._teamService) : super(const TeamState());

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final teams = await _teamService.getAllTeams();
      if (teams.isNotEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            teams: teams,
            currentTeam: teams.first,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, teams: []));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createTeam(CreateTeamRequest request) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _teamService.createTeam(request);
      await loadInitialData();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setCurrentTeam(TeamResponse team) {
    emit(state.copyWith(currentTeam: team));
  }
}
