import 'package:flutter/material.dart';

class GameOverPanel extends StatelessWidget {
  const GameOverPanel({
    super.key,
    required this.score,
    required this.record,
    required this.storageError,
    required this.onRestart,
    required this.soundButton,
  });
  final int score;
  final int record;
  final bool storageError;
  final VoidCallback onRestart;
  final Widget soundButton;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF101021),
      body: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : .92, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: AlertDialog(
              key: const ValueKey('game-over'),
              backgroundColor: const Color(0xFF242139),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFF635480)),
              ),
              scrollable: true,
              icon: const Icon(
                Icons.workspace_premium_rounded,
                size: 48,
                color: Color(0xFFFFBA62),
              ),
              title: const Text(
                'Fim de jogo',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nenhuma das peças restantes cabe no tabuleiro.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pontuação: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorde: $record',
                    style: const TextStyle(color: Color(0xFFFFBA62)),
                  ),
                  if (storageError)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Não foi possível salvar o recorde.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                soundButton,
                FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Jogar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
