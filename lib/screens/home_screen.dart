import 'package:flutter/material.dart';
import 'backlog_screen.dart';
import 'team_screen.dart';
import '../models/team_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  TeamData? _teamData;

  void _onTeamCreated(TeamData teamData) {
    setState(() {
      _teamData = teamData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const BacklogScreen(),
          TeamScreen(
            key: ValueKey(_teamData?.name),
            teamData: _teamData,
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
            icon: Icon(Icons.list),
            label: 'Backlog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Команда',
          ),
        ],
      ),
    );
  }
}

