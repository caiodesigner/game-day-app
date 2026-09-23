import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../storage/high_score_store.dart';
import '../difficulty.dart';
import 'snake_board.dart';

class SnakeController extends ChangeNotifier {
  SnakeController({Random? random, this.highScoreStore, this.autoTick = true})
    : _board = SnakeBoard(random: random) {
    ready = _loadRecord();
    _writes = ready;
  }

  final SnakeBoard _board;
  final HighScoreStore? highScoreStore;
  final bool autoTick;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;
  bool _paused = false;
  bool _foreground = true;
  bool _storageError = false;
  int _record = 0;
  late final Future<void> ready;
  late Future<void> _writes;

  int get size => _board.size;
  List<SnakeCell> get body => _board.body;
  SnakeCell? get food => _board.food;
  SnakeDirection get direction => _board.direction;
  int get score => _board.score;
  int get foodsEaten => _board.foodsEaten;
  int get highScore => _record;
  int get level => Difficulty.levelForScore(score);
  Duration get moveInterval =>
      Duration(milliseconds: max(85, (300 * pow(.85, level - 1)).round()));
  bool get hasStarted => _started;
  bool get isPaused => _paused || !_foreground;
  bool get isGameOver => _board.isGameOver;
  bool get hasWon => _board.hasWon;
  bool get storageError => _storageError;
  Future<void> get pendingWrites => _writes;
  bool get _canAct => !_disposed && _started && !isPaused && !isGameOver;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_disposed || _started || !_foreground || isGameOver) return;
    _started = true;
    _paused = false;
    _schedule();
    _emit();
  }

  bool turn(SnakeDirection direction) {
    if (!_canAct) return false;
    return _board.turn(direction);
  }

  void tick() {
    if (!_canAct) return;
    final result = _board.step();
    if (result == SnakeStep.ate || result == SnakeStep.won) _saveRecord();
    if (isGameOver) _timer?.cancel();
    _emit();
  }

  void _schedule() {
    _timer?.cancel();
    if (!autoTick || !_canAct) return;
    _timer = Timer(moveInterval, () {
      tick();
      _schedule();
    });
  }

  void togglePause() {
    if (_disposed || !_started || isGameOver || !_foreground) return;
    _paused = !_paused;
    _schedule();
    _emit();
  }

  void setForeground(bool foreground) {
    if (_disposed) return;
    _foreground = foreground;
    if (!foreground && _started) _paused = true;
    _schedule();
    _emit();
  }

  void reset() {
    if (_disposed) return;
    _timer?.cancel();
    _board.reset();
    _started = false;
    _paused = false;
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
