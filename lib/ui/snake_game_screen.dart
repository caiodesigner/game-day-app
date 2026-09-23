import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../audio/game_audio.dart';
import '../game/snake/snake_board.dart';
import '../game/snake/snake_controller.dart';
import 'game_over_panel.dart';
import 'piece_view.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key, this.audioFactory});
  final GameAudio Function()? audioFactory;

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen>
    with WidgetsBindingObserver {
  SnakeController? _game;
  GameAudio? _audio;
  bool _soundEnabled = true;
  int _shownScore = 0;
  bool _shownGameOver = false;
  Offset _swipe = Offset.zero;
  bool _swipeHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = widget.audioFactory?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<SnakeController>();
    if (!identical(game, _game)) {
      _game?.removeListener(_onGameChanged);
      _game = game;
      _shownScore = game.score;
      _shownGameOver = game.isGameOver;
      game.addListener(_onGameChanged);
    }
  }

  void _onGameChanged() {
    final game = _game!;
    if (game.isPaused || !game.hasStarted) unawaited(_audio?.stop());
    if (_soundEnabled && !game.isPaused) {
      if (game.isGameOver && !_shownGameOver) {
        unawaited(
          _audio?.play(game.hasWon ? GameSound.clear : GameSound.gameOver),
        );
      } else if (game.score > _shownScore) {
        unawaited(_audio?.play(GameSound.place));
      }
    }
    _shownScore = game.score;
    _shownGameOver = game.isGameOver;
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

  Widget _header(SnakeController game) => Row(
    children: [
      if (Navigator.of(context).canPop())
        IconButton(
          tooltip: 'Voltar aos jogos',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      const Expanded(
        child: Text(
          'SNAKE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
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

  Widget _stats(SnakeController game) => Padding(
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
                key: const ValueKey('snake-score'),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Recorde: ${game.highScore}',
                style: const TextStyle(color: Color(0xFFFFBA62)),
              ),
              Text(
                'Nível ${game.level} · ${game.foodsEaten} comidas',
                style: const TextStyle(fontSize: 12, color: Color(0xFFA9A6C3)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _controls(SnakeController game, {required bool compact}) {
    final size = compact ? 56.0 : 64.0;
    final enabled = game.hasStarted && !game.isPaused && !game.isGameOver;
    Widget arrow(SnakeDirection direction, String label, IconData icon) =>
        IconButton.filledTonal(
          tooltip: label,
          iconSize: 34,
          style: IconButton.styleFrom(fixedSize: Size.square(size)),
          onPressed: enabled ? () => game.turn(direction) : null,
          icon: Icon(icon),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(SnakeDirection.up, 'Mover para cima', Icons.arrow_upward_rounded),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            arrow(
              SnakeDirection.left,
              'Mover para a esquerda',
              Icons.arrow_back_rounded,
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: !game.hasStarted
                  ? 'Começar partida'
                  : game.isPaused
                  ? 'Continuar partida'
                  : 'Pausar partida',
              iconSize: 34,
              style: IconButton.styleFrom(fixedSize: Size.square(size)),
              onPressed: game.hasStarted ? game.togglePause : game.start,
              icon: Icon(
                !game.hasStarted || game.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
            ),
            const SizedBox(width: 8),
            arrow(
              SnakeDirection.right,
              'Mover para a direita',
              Icons.arrow_forward_rounded,
            ),
          ],
        ),
        const SizedBox(height: 4),
        arrow(
          SnakeDirection.down,
          'Mover para baixo',
          Icons.arrow_downward_rounded,
        ),
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Use as setas ou deslize no tabuleiro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFA9A6C3)),
            ),
          ),
      ],
    );
  }

  Widget _board(SnakeController game) => LayoutBuilder(
    builder: (context, constraints) {
      final side = min(480.0, min(constraints.maxWidth, constraints.maxHeight));
      final body = game.body;
      final occupied = body.toSet();
      return Center(
        child: GestureDetector(
          key: const ValueKey('snake-board'),
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            _swipe = Offset.zero;
            _swipeHandled = false;
          },
          onPanUpdate: (details) {
            if (_swipeHandled) return;
            _swipe += details.delta;
            if (max(_swipe.dx.abs(), _swipe.dy.abs()) < 18) return;
            _swipeHandled = true;
            game.turn(
              _swipe.dx.abs() > _swipe.dy.abs()
                  ? (_swipe.dx > 0 ? SnakeDirection.right : SnakeDirection.left)
                  : (_swipe.dy > 0 ? SnakeDirection.down : SnakeDirection.up),
            );
          },
          child: Container(
            width: side,
            height: side,
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
                  itemCount: game.size * game.size,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: game.size,
                  ),
                  itemBuilder: (context, index) {
                    final cell = (x: index % game.size, y: index ~/ game.size);
                    final isHead = cell == body.first;
                    final isFood = cell == game.food;
                    return Semantics(
                      label: isHead
                          ? 'Cabeça da cobrinha'
                          : isFood
                          ? 'Comida'
                          : null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          JewelCell(
                            key: ValueKey('snake-cell-${cell.x}-${cell.y}'),
                            colorId: isHead
                                ? 2
                                : occupied.contains(cell)
                                ? 1
                                : isFood
                                ? 3
                                : 0,
                          ),
                          if (isHead)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Transform.rotate(
                                angle: game.direction.index * pi / 2,
                                child: const CustomPaint(painter: _SnakeEyes()),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (!game.hasStarted || game.isPaused)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0xCC101021),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              game.hasStarted
                                  ? 'Pausado'
                                  : 'Pronto para jogar?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: game.hasStarted
                                  ? game.togglePause
                                  : game.start,
                              child: Text(
                                game.hasStarted ? 'Continuar' : 'Começar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SnakeController>();
    if (game.isGameOver) {
      return GameOverPanel(
        title: game.hasWon ? 'Você venceu!' : 'Fim de jogo',
        message: game.hasWon
            ? 'A cobrinha preencheu todo o tabuleiro!'
            : 'A cobrinha bateu na parede ou no próprio corpo.',
        score: game.score,
        record: game.highScore,
        storageError: game.storageError,
        onRestart: game.reset,
        soundButton: _soundButton(),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            game.turn(SnakeDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            game.turn(SnakeDirection.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            game.turn(SnakeDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            game.turn(SnakeDirection.right),
        const SingleActivator(LogicalKeyboardKey.space): game.hasStarted
            ? game.togglePause
            : game.start,
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
                          'Recorde não salvo. Tentaremos novamente ao comer.',
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
                                const SizedBox(height: 8),
                                _controls(game, compact: true),
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
                      _controls(game, compact: false),
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

class _SnakeEyes extends CustomPainter {
  const _SnakeEyes();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF101021);
    for (final x in [.3, .7]) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * .28),
        size.shortestSide * .12,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SnakeEyes oldDelegate) => false;
}
