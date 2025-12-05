import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:pulse_mobile/models/team_data.dart';
import '../../core/api_client.dart';
import '../../models/team_member_api.dart';
import '../../models/team_response.dart';
import '../../notifiers/current_project_notifier.dart';
import 'cubit/team_cubit_cubit.dart';
import '../../services/team_service.dart';
import '../../widgets/exception_widget.dart';
import '../create_team_screen.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TeamCubit(
        TeamService(ApiClient()),
        context.read<CurrentProjectNotifier>(),
      )..loadInitialData(),
      child: const TeamView(),
    );
  }
}

class TeamView extends StatelessWidget {
  const TeamView({super.key});

  // Цвета
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);
  static const Color accentColor = Color(0xFF73A168);
  static const Color textColor = Color(0xFF000000);
  static const Color dividerColor = Color(0xFF636363);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocBuilder<TeamCubit, TeamState>(
          builder: (context, state) {
            if (state.isLoading) {
              return _buildLoadingState();
            }
            if (state.error != null) {
              return ExceptionWidget(
                title: 'Не удалось загрузить команды',
                message: state.error ?? 'Произошла ошибка',
                onRestart: () => context.read<TeamCubit>().loadInitialData(),
              );
            }
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
          const SizedBox(height: 24),
          Text('Загрузка...', style: TextStyle(color: textColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, TeamState state) {
    return ListView(
      children: [
        _buildHeader(context, state),
        _buildTeamsList(context, state),
        if (state.currentTeam != null) ...[
          _buildDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'Участники «${state.currentTeam!.name}»',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildTeamMembersSection(state),
        ],
      ],
    );
  }

  Widget _buildTeamsList(BuildContext context, TeamState state) {
    if (state.teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Команды не найдены. Создайте первую, чтобы начать!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.teams.map((team) {
        final isSelected = state.currentTeam?.id == team.id;
        return _buildTeamItem(context, team, isSelected);
      }).toList(),
    );
  }

  Widget _buildTeamItem(
    BuildContext context,
    TeamResponse team,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (team.description != null && team.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              team.description!,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: isSelected
                ? Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      color: accentColor,
                      size: 20,
                    ),
                    label: const Text(
                      'Выбрано',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: accentColor.withValues(alpha: 0.2),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                : OutlinedButton(
                    onPressed: () {
                      context.read<TeamCubit>().setCurrentTeam(team);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Выбрать команду'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeamState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Ваши команды',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final result = await Navigator.push<TeamData>(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTeamScreen(
                    onTeamCreated: (teamData) {
                      Navigator.of(context).pop(teamData);
                    },
                  ),
                ),
              );
              if (result != null && context.mounted) {
                context.read<TeamCubit>().loadInitialData();
              }
            },
            tooltip: 'Создать команду',
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection(TeamState state) {
    if (state.currentTeam == null || state.currentTeam!.members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          'В этой команде пока нет участников.',
          style: TextStyle(color: textColor.withValues(alpha: 0.6)),
        ),
      );
    }

    final teamMembers = state.currentTeam!.members;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            teamMembers.length,
            (index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildTeamMemberCard(teamMembers[index]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMemberApi member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.role,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.userName,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 1,
      color: dividerColor,
    );
  }
}
