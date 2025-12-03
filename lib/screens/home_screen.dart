import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'kanban_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VoidCallback? _addTaskCallback;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfafafa),
        elevation: 0,
        title: const Text(
          'Pulse',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF73a168),
          labelColor: const Color(0xFF000000),
          unselectedLabelColor: const Color(0xFF636363),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Задачи',
            ),
            Tab(
              icon: Icon(Icons.view_kanban),
              text: 'Канбан',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TasksScreen(
            onAddTaskCallback: (callback) {
              setState(() {
                _addTaskCallback = callback;
              });
            },
          ),
          KanbanBoardScreen(
            onAddTaskCallback: (callback) {
              setState(() {
                _addTaskCallback = callback;
              });
            },
          ),
        ],
      ),
      floatingActionButton: _addTaskCallback != null
          ? FloatingActionButton(
              onPressed: _addTaskCallback,
              backgroundColor: const Color(0xFF636363),
              tooltip: 'Добавить задачу',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

