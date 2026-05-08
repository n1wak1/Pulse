import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import '../../../models/team_response.dart';
import '../../../notifiers/current_project_notifier.dart';
import '../../../services/team_service.dart';
import '../../../core/api_exception.dart';
import '../../../models/team_invitation.dart';

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
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final teams = await _teamService.getAllTeams();
      if (teams.isNotEmpty) {
        _currentProjectNotifier.setProject(teams.first);
        emit(state.copyWith(isLoading: false, teams: teams, error: null));
        await loadInvitations();
      } else {
        _currentProjectNotifier.clearProject();
        emit(state.copyWith(
          isLoading: false,
          teams: [],
          currentTeam: null,
          error: null,
        ));
        // Входящие приглашения привязаны к пользователю, а не к команде —
        // загружаем даже при нуле команд.
        await loadInvitations();
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setCurrentTeam(TeamResponse team) {
    _currentProjectNotifier.setProject(team);
    unawaited(loadInvitations());
  }

  Future<void> loadInvitations() async {
    emit(state.copyWith(isInvitesLoading: true, inviteActionError: null));
    try {
      final incoming = await _teamService.getIncomingInvitations();
      final teamId = state.currentTeam?.id;
      final outgoing = (teamId != null && teamId != 0)
          ? await _teamService.getTeamOutgoingInvitations(teamId: teamId)
          : <TeamInvitation>[];
      emit(state.copyWith(
        isInvitesLoading: false,
        incomingInvites: incoming,
        outgoingInvites: outgoing,
        inviteActionError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInvitesLoading: false,
        inviteActionError: e.toString(),
      ));
    }
  }

  Future<void> inviteByEmail({
    required String email,
    required String role,
  }) async {
    final teamId = state.currentTeam?.id;
    if (teamId == null || teamId == 0) return;

    emit(state.copyWith(inviteActionError: null));
    try {
      await _teamService.lookupUserByEmail(email);
    } on ApiException catch (e) {
      // 404 => "Ресурс не найден." => показываем "Пользователь не найден"
      if (e.message.contains('не найден') || e.message.contains('404')) {
        emit(state.copyWith(inviteActionError: 'Пользователь не найден'));
        return;
      }
      emit(state.copyWith(inviteActionError: e.message));
      return;
    } catch (e) {
      emit(state.copyWith(inviteActionError: e.toString()));
      return;
    }

    try {
      await _teamService.inviteUserToTeam(teamId: teamId, email: email, role: role);
      await loadInvitations();
    } catch (e) {
      emit(state.copyWith(inviteActionError: e.toString()));
    }
  }

  Future<void> acceptInvite(int invitationId) async {
    emit(state.copyWith(inviteActionError: null));
    try {
      await _teamService.acceptInvitation(invitationId);
      await loadInvitations();
      await loadInitialData(); // обновим команды/участников после принятия
    } catch (e) {
      emit(state.copyWith(inviteActionError: e.toString()));
    }
  }

  Future<void> declineInvite(int invitationId) async {
    emit(state.copyWith(inviteActionError: null));
    try {
      await _teamService.declineInvitation(invitationId);
      await loadInvitations();
    } catch (e) {
      emit(state.copyWith(inviteActionError: e.toString()));
    }
  }
}
