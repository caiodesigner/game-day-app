import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../storage/high_score_store.dart';
import '../difficulty.dart';
import '../piece.dart';
import 'falling_board.dart';

class FallingController extends ChangeNotifier {
  FallingController({
    Random? random,
    this.nextPiece,
    this.highScoreStore,
    this.autoStart = true,
  }) : _random = random ?? Random() {
    _next = _draw();
    _spawn();
    ready = _loadRecord();
    _writes = ready;
    _schedule();
  }

  final Random _random;
  final Piece Function()? nextPiece;
  final HighScoreStore? highScoreStore;
  final bool autoStart;
  final FallingBoard _board = FallingBoard();
  final List<Piece> _bag = [];
  Timer? _timer;
  bool _disposed = false;
  bool _paused = false;
  bool _foreground = true;
  bool _gameOver = false;
  bool _storageError = false;
  int _score = 0;
  int _record = 0;
  int _locked = 0;
  int _lines = 0;
  int _x = 0;
  int _y = 0;
  late Piece _active;
  late Piece _next;
  FallingPlacement? _lastPlacement;
  late final Future<void> ready;
  late Future<void> _writes;

  List<List<int>> get cells => _board.cells;
  Piece get active => _active;
  Piece get next => _next;
  int get x => _x;
  int get y => _y;
  int get score => _score;
  int get highScore => _record;
  int get lockedPieces => _locked;
  int get clearedLines => _lines;
  int get level => Difficulty.levelForScore(score);
  Duration get fallInterval =>
      Duration(milliseconds: max(90, (800 * pow(.85, level - 1)).round()));
  bool get isPaused => _paused || !_foreground;
  bool get isGameOver => _gameOver;
  bool get storageError => _storageError;
  bool get _canAct => !_disposed && !isPaused && !isGameOver;
  FallingPlacement? get lastPlacement => _lastPlacement;
  Future<void> get pendingWrites => _writes;

  int get landingY {
    var row = _y;
    while (_board.fits(_active, _x, row + 1)) {
      row++;
    }
    return row;
  }

  Piece _draw() {
    if (nextPiece != null) return nextPiece!();
    if (_bag.isEmpty) _bag.addAll([...FallingPieces.all]..shuffle(_random));
    return Piece(_bag.removeLast().cells, colorId: 1 + _random.nextInt(5));
  }

  void _spawn() {
    _active = _next;
    _next = _draw();
    final width = _active.cells.map((cell) => cell.x).reduce(max) + 1;
    _x = (FallingBoard.width - width) ~/ 2;
    _y = 0;
    _gameOver = !_board.fits(_active, _x, _y);
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    if (!autoStart || !_canAct) return;
    _timer = Timer(fallInterval, () {
      stepDown();
      _schedule();
    });
  }

  bool move(int direction) {
    if (!_canAct ||
        (direction != -1 && direction != 1) ||
        !_board.fits(_active, _x + direction, _y)) {
      return false;
    }
    _x += direction;
    _emit();
    return true;
  }

  bool rotate() {
    if (!_canAct) return false;
    final rotated = FallingPieces.rotate(_active);
    // Small horizontal kicks let pieces rotate against either wall.
    for (final offset in [0, -1, 1, -2, 2, -3, 3]) {
      if (_board.fits(rotated, _x + offset, _y)) {
        _active = rotated;
        _x += offset;
        _emit();
        return true;
      }
    }
    return false;
  }

  void stepDown() {
    if (!_canAct) return;
    if (_board.fits(_active, _x, _y + 1)) {
      _y++;
      _emit();
    } else {
      _lock();
    }
  }

  void drop() {
    if (!_canAct) return;
    _y = landingY;
    _lock();
  }

  void _lock() {
    final placement = _board.lock(_active, _x, _y)!;
    _lastPlacement = placement;
    _score += placement.points;
    _lines += placement.rows.length;
    _locked++;
    _saveRecord();
    _spawn();
    _schedule();
    _emit();
  }

  void togglePause() {
    if (_disposed || _gameOver || !_foreground) return;
    _paused = !_paused;
    _schedule();
    _emit();
  }

  void setForeground(bool foreground) {
    if (_disposed) return;
    _foreground = foreground;
    // Require an explicit resume after an interruption.
    if (!foreground) _paused = true;
    _schedule();
    _emit();
  }

  void reset() {
    if (_disposed) return;
    _board.reset();
    _bag.clear();
    _score = _locked = _lines = 0;
    _lastPlacement = null;
    _paused = false;
    _next = _draw();
    _spawn();
    _schedule();
    _emit();
  }

  Future<void> _loadRecord() async {
    try {
      final stored = await highScoreStore?.read() ?? 0;
      _record = max(_record, stored);
    } catch (_) {
      _storageError = true;
    }
    _emit();
  }

  void _saveRecord() {
    _record = max(_record, score);
    if (highScoreStore == null) return;
    _writes = _writes.then((_) async {
      try {
        final stored = await highScoreStore!.read();
        _record = max(_record, stored);
        if (_record > stored) await highScoreStore!.write(_record);
        _storageError = false;
      } catch (_) {
        _storageError = true;
      }
      _emit();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
