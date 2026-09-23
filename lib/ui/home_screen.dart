import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/game_audio.dart';
import '../game/game_controller.dart';
import '../storage/high_score_store.dart';
import 'game_screen.dart';
import 'falling_game_screen.dart';
import '../game/falling/falling_controller.dart';

/// Each game owns its controller and resources within its route.
final _games =
    <
      ({
        String id,
        String title,
        String description,
        IconData icon,
        WidgetBuilder builder,
      })
    >[
      (
        id: 'block-puzzle',
        title: 'Block Puzzle',
        description: 'Encaixe as peças, complete linhas e supere seu recorde.',
        icon: Icons.grid_view_rounded,
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              GameController(highScoreStore: PreferencesHighScoreStore()),
          child: GameScreen(audioFactory: LocalGameAudio.new),
        ),
      ),
      (
        id: 'block-fall',
        title: 'Block Fall',
        description:
            'Gire as peças em queda, complete linhas e desafie a velocidade.',
        icon: Icons.view_comfy_rounded,
        builder: (_) => ChangeNotifierProvider(
          create: (_) => FallingController(
            highScoreStore: PreferencesHighScoreStore(
              storageKey: PreferencesHighScoreStore.fallingKey,
            ),
          ),
          child: FallingGameScreen(audioFactory: LocalGameAudio.new),
        ),
      ),
    ];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101021),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                const Text(
                  'GAME DAY APP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escolha seu próximo desafio.',
                  style: TextStyle(fontSize: 18, color: Color(0xFFA9A6C3)),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Seus jogos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                for (final game in _games)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: const Color(0xFF242139),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Color(0xFF514B68)),
                      ),
                      child: InkWell(
                        key: ValueKey('game-${game.id}'),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: game.builder,
                            settings: RouteSettings(name: '/games/${game.id}'),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                game.icon,
                                size: 48,
                                color: const Color(0xFF9A7BFF),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                game.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                game.description,
                                style: const TextStyle(
                                  color: Color(0xFFA9A6C3),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Color(0xFF48D6D2),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Jogar',
                                    style: TextStyle(
                                      color: Color(0xFF48D6D2),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
