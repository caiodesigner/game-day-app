import 'package:flutter/material.dart';

void main() {
  runApp(const BlockPuzzleApp());
}

class BlockPuzzleApp extends StatelessWidget {
  const BlockPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(body: Center(child: Text('Block Puzzle'))),
    );
  }
}
