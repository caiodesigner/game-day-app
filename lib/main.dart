import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const GameDayApp());
}

class GameDayApp extends StatelessWidget {
  const GameDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Day App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
