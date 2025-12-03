import 'package:flutter/material.dart';
import 'team_screen.dart';
import 'create_team_screen.dart';
import '../models/team_data.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  TeamData? _teamData;

  void _onTeamCreated(TeamData teamData) {
    setState(() {
      _teamData = teamData;
      // Переключаемся на экран команды
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TeamScreen(
            key: ValueKey(_teamData?.name),
            teamData: _teamData,
          ),
          CreateTeamScreen(
            onTeamCreated: _onTeamCreated,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF73A168),
        unselectedItemColor: const Color(0xFF636363),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Команда',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Создать',
          ),
        ],
      ),
    );
  }
}
