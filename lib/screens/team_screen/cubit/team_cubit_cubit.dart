import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../models/team_response.dart';
import '../../../notifiers/current_project_notifier.dart';
import '../../../services/team_service.dart';

part 'team_cubit_state.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamService _teamService;
  final CurrentProjectNotifier _currentProjectNotifier;

  TeamCubit(this._teamService, this._currentProjectNotifier)
    : super(const TeamState()) {
    _currentProjectNotifier.addListener(_onProjectChanged);
  }

  void _onProjectChanged() {
    emit(state.copyWith(currentTeam: _currentProjectNotifier.currentProject));
  }

  @override
  Future<void> close() {
    _currentProjectNotifier.removeListener(_onProjectChanged);
    return super.close();
  }

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final teams = await _teamService.getAllTeams();
      if (teams.isNotEmpty) {
        _currentProjectNotifier.setProject(teams.first);
        emit(state.copyWith(isLoading: false, teams: teams));
      } else {
        emit(state.copyWith(isLoading: false, teams: []));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setCurrentTeam(TeamResponse team) {
    _currentProjectNotifier.setProject(team);
  }
}
