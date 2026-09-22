import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/game_controller.dart';
import 'ui/game_screen.dart';
import 'audio/game_audio.dart';
import 'storage/high_score_store.dart';

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
      home: ChangeNotifierProvider(
        create: (_) =>
            GameController(highScoreStore: PreferencesHighScoreStore()),
        child: GameScreen(audioFactory: LocalGameAudio.new),
      ),
    );
  }
}
