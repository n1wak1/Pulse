import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF73a168),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFfafafa),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
