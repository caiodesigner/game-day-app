import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../audio/game_audio.dart';
import '../game/falling/falling_board.dart';
import '../game/falling/falling_controller.dart';
import 'game_over_panel.dart';
import 'piece_view.dart';

class FallingGameScreen extends StatefulWidget {
  const FallingGameScreen({super.key, this.audioFactory});
  final GameAudio Function()? audioFactory;

  @override
  State<FallingGameScreen> createState() => _FallingGameScreenState();
}

class _FallingGameScreenState extends State<FallingGameScreen>
    with WidgetsBindingObserver {
  FallingController? _game;
  GameAudio? _audio;
  bool _soundEnabled = true;
  int _shownLocks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = widget.audioFactory?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<FallingController>();
    if (!identical(game, _game)) {
      _game?.removeListener(_onGameChanged);
      _game = game;
      _shownLocks = game.lockedPieces;
      game.addListener(_onGameChanged);
    }
  }

  void _onGameChanged() {
    final game = _game!;
    if (game.isPaused) unawaited(_audio?.stop());
    if (game.lockedPieces == _shownLocks) return;
    _shownLocks = game.lockedPieces;
    if (_shownLocks == 0) {
      unawaited(_audio?.stop());
    } else if (_soundEnabled && !game.isPaused) {
      unawaited(
        _audio?.play(
          game.isGameOver
              ? GameSound.gameOver
              : game.lastPlacement!.rows.isEmpty
              ? GameSound.place
              : GameSound.clear,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _game?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.removeListener(_onGameChanged);
    unawaited(_audio?.dispose());
    super.dispose();
  }

  Widget _soundButton() => IconButton(
    tooltip: _soundEnabled ? 'Silenciar sons' : 'Ativar sons',
    icon: Icon(
      _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
    ),
    onPressed: () {
      setState(() => _soundEnabled = !_soundEnabled);
      if (!_soundEnabled) unawaited(_audio?.stop());
    },
  );

  Widget _header(FallingController game) => Row(
    children: [
      if (Navigator.of(context).canPop())
        IconButton(
          tooltip: 'Voltar aos jogos',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      const Expanded(
        child: Text(
          'BLOCK FALL',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      _soundButton(),
      IconButton(
        tooltip: 'Reiniciar partida',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: game.reset,
      ),
    ],
  );

  Widget _stats(FallingController game) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PONTUAÇÃO',
                style: TextStyle(fontSize: 11, color: Color(0xFFA9A6C3)),
              ),
              Text(
                '${game.score}',
                key: const ValueKey('falling-score'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recorde: ${game.highScore}',
                style: const TextStyle(color: Color(0xFFFFBA62)),
              ),
              Text(
                'Nível ${game.level} · ${game.clearedLines} linhas',
                style: const TextStyle(fontSize: 12, color: Color(0xFFA9A6C3)),
              ),
            ],
          ),
        ),
        Column(
          children: [
            const Text(
              'PRÓXIMA',
              style: TextStyle(fontSize: 10, color: Color(0xFFA9A6C3)),
            ),
            SizedBox(
              width: 60,
              height: 36,
              child: Center(child: PieceView(piece: game.next, cellSize: 12)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _controls(FallingController game) {
    final enabled = !game.isPaused && !game.isGameOver;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: 'Mover para a esquerda',
              style: IconButton.styleFrom(fixedSize: const Size.square(64)),
              iconSize: 36,
              onPressed: enabled ? () => game.move(-1) : null,
              icon: const Icon(Icons.arrow_left_rounded),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: 'Girar peça',
              style: IconButton.styleFrom(fixedSize: const Size.square(76)),
              iconSize: 40,
              onPressed: enabled ? game.rotate : null,
              icon: const Icon(Icons.rotate_right_rounded),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Mover para a direita',
              style: IconButton.styleFrom(fixedSize: const Size.square(64)),
              iconSize: 36,
              onPressed: enabled ? () => game.move(1) : null,
              icon: const Icon(Icons.arrow_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: 'Descer um passo',
              style: IconButton.styleFrom(fixedSize: const Size.square(56)),
              iconSize: 28,
              onPressed: enabled ? game.stepDown : null,
              icon: const Icon(Icons.arrow_downward_rounded),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Soltar peça',
              style: IconButton.styleFrom(fixedSize: const Size.square(56)),
              iconSize: 28,
              onPressed: enabled ? game.drop : null,
              icon: const Icon(Icons.vertical_align_bottom_rounded),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: game.isPaused ? 'Continuar partida' : 'Pausar partida',
              style: IconButton.styleFrom(fixedSize: const Size.square(56)),
              iconSize: 28,
              onPressed: game.togglePause,
              icon: Icon(
                game.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Gire e encaixe as peças para completar linhas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFA9A6C3)),
          ),
        ),
      ],
    );
  }

  Widget _board(FallingController game) => LayoutBuilder(
    builder: (context, constraints) {
      final cellSize = min(
        (constraints.maxWidth - 8) / FallingBoard.width,
        (constraints.maxHeight - 8) / FallingBoard.height,
      );
      final cells = game.cells;
      final active = {
        for (final cell in game.active.cells)
          (x: game.x + cell.x, y: game.y + cell.y),
      };
      final ghost = {
        for (final cell in game.active.cells)
          (x: game.x + cell.x, y: game.landingY + cell.y),
      };
      return Center(
        child: Container(
          key: const ValueKey('falling-board'),
          width: cellSize * FallingBoard.width + 8,
          height: cellSize * FallingBoard.height + 8,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF23233B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3C385A)),
          ),
          child: Stack(
            children: [
              GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: FallingBoard.width * FallingBoard.height,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: FallingBoard.width,
                ),
                itemBuilder: (context, index) {
                  final x = index % FallingBoard.width;
                  final y = index ~/ FallingBoard.width;
                  final isActive = active.contains((x: x, y: y));
                  return JewelCell(
                    key: ValueKey('falling-cell-$x-$y'),
                    colorId: isActive ? game.active.colorId : cells[y][x],
                    preview: !isActive && ghost.contains((x: x, y: y))
                        ? true
                        : null,
                    previewColorId: game.active.colorId,
                  );
                },
              ),
              if (game.isPaused)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xDD101021),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pausado',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: game.togglePause,
                            child: const Text('Continuar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final game = context.watch<FallingController>();
    if (game.isGameOver) {
      return GameOverPanel(
        score: game.score,
        record: game.highScore,
        storageError: game.storageError,
        message: 'As peças chegaram ao topo do tabuleiro.',
        onRestart: game.reset,
        soundButton: _soundButton(),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            game.move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            game.move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): game.rotate,
        const SingleActivator(LogicalKeyboardKey.arrowDown): game.stepDown,
        const SingleActivator(LogicalKeyboardKey.space): game.drop,
        const SingleActivator(LogicalKeyboardKey.keyP): game.togglePause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF101021),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final panel = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(game),
                      _stats(game),
                      if (game.storageError)
                        const Text(
                          'Recorde não salvo. Tentaremos novamente na próxima jogada.',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                  if (constraints.maxWidth > constraints.maxHeight * 1.2) {
                    return Row(
                      children: [
                        Expanded(child: _board(game)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: min(340, constraints.maxWidth * .52),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                panel,
                                const SizedBox(height: 16),
                                _controls(game),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      panel,
                      Expanded(child: _board(game)),
                      const SizedBox(height: 8),
                      _controls(game),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
