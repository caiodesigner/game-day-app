import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_controller.dart';
import '../game/piece.dart';
import '../audio/game_audio.dart';
import 'game_over_panel.dart';

const _palette = [
  Color(0xFF9A7BFF),
  Color(0xFF48D6D2),
  Color(0xFFFFBA62),
  Color(0xFFEF78B1),
  Color(0xFF6EACFF),
];

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.audioFactory});
  final GameAudio Function()? audioFactory;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _effect;
  GameController? _game;
  GameAudio? _audio;
  MoveFeedback? _shownMove;
  bool _soundEnabled = true;
  bool _foreground = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = widget.audioFactory?.call();
    _effect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _effect.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        if (_game?.isGameOver ?? false) _play(GameSound.gameOver);
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final game = context.read<GameController>();
    if (!identical(game, _game)) {
      _game?.removeListener(_onGameChanged);
      _game = game;
      _shownMove = game.lastMove;
      game.addListener(_onGameChanged);
    }
  }

  void _play(GameSound sound) {
    if (_soundEnabled && _foreground) unawaited(_audio?.play(sound));
  }

  void _onGameChanged() {
    final move = _game!.lastMove;
    if (identical(move, _shownMove)) return;
    _shownMove = move;
    if (move == null) {
      _effect.reset();
      unawaited(_audio?.stop());
    } else {
      _play(
        move.result.clearedLineCount > 0 ? GameSound.clear : GameSound.place,
      );
      _effect.duration = _reduceMotion
          ? Duration.zero
          : Duration(milliseconds: move.clearedCells.isEmpty ? 140 : 340);
      _effect.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_audio?.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.removeListener(_onGameChanged);
    _effect.dispose();
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

  ({DockPiece entry, int x, int y})? _preview;

  void _clearPreview() {
    if (_preview != null && mounted) setState(() => _preview = null);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    if (game.isGameOver && !_effect.isAnimating) {
      return GameOverPanel(
        score: game.score,
        record: game.highScore,
        storageError: game.storageError,
        soundButton: _soundButton(),
        onRestart: () {
          _clearPreview();
          game.reset();
        },
      );
    }
    final cells = game.cells;
    final preview = _preview;
    final valid =
        preview != null && game.canPlace(preview.entry, preview.x, preview.y);
    final highlighted = <({int x, int y})>{
      if (preview != null)
        for (final cell in preview.entry.piece.cells)
          (x: preview.x + cell.x, y: preview.y + cell.y),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF101021),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = min(
              480.0,
              min(
                constraints.maxWidth - 32,
                max(160.0, constraints.maxHeight - 300),
              ),
            );
            final cellSize = side / 8;
            return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: min(constraints.maxWidth, 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'BLOCK PUZZLE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                              onPressed: game.dragging == null
                                  ? () {
                                      _clearPreview();
                                      game.reset();
                                    }
                                  : null,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PONTUAÇÃO',
                                  style: TextStyle(
                                    color: Color(0xFFA9A6C3),
                                    letterSpacing: 2,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${game.score}',
                                  key: const ValueKey('score'),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Recorde: ${game.highScore}',
                                  key: const ValueKey('high-score'),
                                  style: const TextStyle(
                                    color: Color(0xFFFFBA62),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rodada ${game.round}',
                                  style: const TextStyle(
                                    color: Color(0xFFA9A6C3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (game.storageError)
                          const Text(
                            'Recorde não salvo. Tentaremos novamente na próxima jogada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF23233B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF3C385A)),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: SizedBox(
                            width: side - 8,
                            height: side - 8,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: 64,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                  ),
                              itemBuilder: (context, index) {
                                final x = index % 8;
                                final y = index ~/ 8;
                                return DragTarget<DockPiece>(
                                  key: ValueKey('cell-$x-$y'),
                                  onWillAcceptWithDetails: (details) {
                                    setState(
                                      () => _preview = (
                                        entry: details.data,
                                        x: x,
                                        y: y,
                                      ),
                                    );
                                    return !_effect.isAnimating &&
                                        game.canPlace(details.data, x, y);
                                  },
                                  onLeave: (_) {
                                    if (_preview?.x == x && _preview?.y == y) {
                                      _clearPreview();
                                    }
                                  },
                                  onAcceptWithDetails: (details) {
                                    if (!_effect.isAnimating) {
                                      game.place(details.data, x, y);
                                    }
                                    _clearPreview();
                                  },
                                  builder: (context, candidates, rejected) =>
                                      Semantics(
                                        label:
                                            'Linha ${y + 1}, coluna ${x + 1}, ${cells[y][x] == 0 ? 'vazia' : 'ocupada'}',
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            JewelCell(
                                              colorId: cells[y][x],
                                              preview:
                                                  highlighted.contains((
                                                    x: x,
                                                    y: y,
                                                  ))
                                                  ? valid
                                                  : null,
                                            ),
                                            if (_effect.isAnimating &&
                                                (_shownMove?.clearedCells
                                                        .containsKey((
                                                          x: x,
                                                          y: y,
                                                        )) ??
                                                    false))
                                              IgnorePointer(
                                                child: AnimatedBuilder(
                                                  animation: _effect,
                                                  builder: (context, child) =>
                                                      Opacity(
                                                        opacity:
                                                            1 - _effect.value,
                                                        child: Transform.scale(
                                                          scale:
                                                              1 -
                                                              .8 *
                                                                  _effect.value,
                                                          child: child,
                                                        ),
                                                      ),
                                                  child: JewelCell(
                                                    key: ValueKey(
                                                      'clearing-$x-$y',
                                                    ),
                                                    colorId:
                                                        _shownMove!
                                                            .clearedCells[(
                                                          x: x,
                                                          y: y,
                                                        )]!,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _shownMove == null
                              ? 'Arraste as peças para o tabuleiro'
                              : _shownMove!.result.clearedLineCount > 1
                              ? 'Combo ×${_shownMove!.result.clearedLineCount} · +${_shownMove!.result.points} pontos'
                              : '+${_shownMove!.result.points} pontos · Continue assim!',
                          key: const ValueKey('move-feedback'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFB8B4CE)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Expanded(
                                  child: Center(
                                    child: _dockSlot(
                                      game,
                                      i,
                                      (cellSize - 1),
                                      min(
                                        20.0,
                                        (constraints.maxWidth - 64) / 15,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Text(
                          'Complete linhas ou colunas para pontuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF85809E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dockSlot(
    GameController game,
    int index,
    double fullSize,
    double smallSize,
  ) {
    final entry = game.dock[index];
    if (entry == null) {
      return const Icon(Icons.check_rounded, color: Color(0xFF514B68));
    }
    final piece = PieceView(piece: entry.piece, cellSize: smallSize);
    return Draggable<DockPiece>(
      key: ObjectKey(entry),
      hitTestBehavior: HitTestBehavior.opaque,
      data: entry,
      maxSimultaneousDrags: game.dragging == null && !_effect.isAnimating
          ? 1
          : 0,
      // The pointer anchors the center of the top-left grid cell at either scale.
      dragAnchorStrategy: (_, _, _) => Offset(fullSize / 2, fullSize / 2),
      onDragStarted: () => game.beginDrag(entry),
      onDragEnd: (_) {
        game.endDrag();
        _clearPreview();
      },
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: .8,
          child: PieceView(piece: entry.piece, cellSize: fullSize),
        ),
      ),
      childWhenDragging: Opacity(opacity: .18, child: piece),
      child: Semantics(
        label: 'Peça ${index + 1}, ${entry.piece.blockCount} blocos',
        child: SizedBox(
          key: ValueKey('dock-$index'),
          width: 5 * smallSize,
          height: 5 * smallSize,
          child: Center(child: piece),
        ),
      ),
    );
  }
}

class JewelCell extends StatelessWidget {
  const JewelCell({super.key, required this.colorId, this.preview});
  final int colorId;
  final bool? preview;

  @override
  Widget build(BuildContext context) {
    final color = preview != null
        ? (preview! ? const Color(0xFF72EBC5) : const Color(0xFFFF6C87))
        : colorId == 0
        ? const Color(0xFF19192D)
        : _palette[(colorId - 1) % _palette.length];
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color,
        border: Border.all(
          color: colorId == 0 && preview == null
              ? const Color(0xFF2E2B44)
              : Color.lerp(color, Colors.white, .4)!,
          width: 1.5,
        ),
        gradient: colorId == 0 && preview == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, .24)!],
              ),
      ),
    );
  }
}

class PieceView extends StatelessWidget {
  const PieceView({super.key, required this.piece, required this.cellSize});
  final Piece piece;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final width = piece.cells.map((cell) => cell.x).reduce(max) + 1;
    final height = piece.cells.map((cell) => cell.y).reduce(max) + 1;
    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: cell.x * cellSize,
              top: cell.y * cellSize,
              width: cellSize,
              height: cellSize,
              child: JewelCell(colorId: piece.colorId),
            ),
        ],
      ),
    );
  }
}
