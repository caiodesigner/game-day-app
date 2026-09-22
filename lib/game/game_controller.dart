import 'dart:math';

import 'package:flutter/foundation.dart';

import 'board_logic.dart';
import 'piece.dart';
import '../storage/high_score_store.dart';

/// Each dock entry has its own identity, even when shapes repeat.
class DockPiece {
  DockPiece(this.piece);
  final Piece piece;
}

/// Immutable visual event. Cleared cells retain their pre-clear colors.
class MoveFeedback {
  MoveFeedback(this.result, Map<({int x, int y}), int> clearedCells)
    : clearedCells = Map.unmodifiable(clearedCells);
  final PlacementResult result;
  final Map<({int x, int y}), int> clearedCells;
}

class GameController extends ChangeNotifier {
  GameController({Random? random, this.nextPiece, this.highScoreStore})
    : _random = random ?? Random() {
    _refill();
    _checkGameOver();
    ready = _loadRecord();
    _writes = ready;
  }

  final HighScoreStore? highScoreStore;
  late final Future<void> ready;
  late Future<void> _writes;
  bool _disposed = false;
  bool _storageError = false;
  int _highScore = 0;
  bool _isGameOver = false;

  int get highScore => _highScore;
  bool get isGameOver => _isGameOver;
  bool get storageError => _storageError;
  Future<void> get pendingWrites => _writes;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadRecord() async {
    if (highScoreStore == null) return;
    try {
      final stored = await highScoreStore!.read();
      _highScore = max(_highScore, stored);
    } catch (_) {
      _storageError = true;
    }
    _emit();
  }

  void _saveRecord() {
    _highScore = max(_highScore, score);
    if (highScoreStore == null) return;
    // Serialize writes; a late load or an older move must never lower the record.
    _writes = _writes.then((_) async {
      try {
        final stored = await highScoreStore!.read();
        _highScore = max(_highScore, stored);
        if (_highScore > stored) await highScoreStore!.write(_highScore);
        _storageError = false;
      } catch (_) {
        _storageError = true;
      }
      _emit();
    });
  }

  void _checkGameOver() {
    _isGameOver = !_board.hasAnyMove(
      _dock.whereType<DockPiece>().map((entry) => entry.piece),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final Random _random;
  final Piece Function()? nextPiece;
  final BoardLogic _board = BoardLogic();
  final List<DockPiece?> _dock = List.filled(3, null);
  DockPiece? _dragging;
  int _round = 1;
  MoveFeedback? _lastMove;
  MoveFeedback? get lastMove => _lastMove;

  List<List<int>> get cells => _board.cells;
  int get score => _board.score;
  int get round => _round;
  List<DockPiece?> get dock => List.unmodifiable(_dock);
  DockPiece? get dragging => _dragging;

  void _refill() {
    for (var i = 0; i < 3; i++) {
      final shape =
          nextPiece?.call() ?? Pieces.all[_random.nextInt(Pieces.all.length)];
      _dock[i] = DockPiece(Piece(shape.cells, colorId: 1 + _random.nextInt(5)));
    }
  }

  bool canPlace(DockPiece entry, int x, int y) =>
      !_isGameOver &&
      _dock.contains(entry) &&
      _board.canPlace(entry.piece, x: x, y: y);

  bool beginDrag(DockPiece entry) {
    if (_isGameOver || _dragging != null || !_dock.contains(entry)) {
      return false;
    }
    _dragging = entry;
    notifyListeners();
    return true;
  }

  void endDrag() {
    if (_dragging == null) return;
    _dragging = null;
    notifyListeners();
  }

  PlacementResult? place(DockPiece entry, int x, int y) {
    if (_isGameOver) return null;
    if (_dragging != null && !identical(_dragging, entry)) return null;
    final index = _dock.indexOf(entry);
    if (index < 0) return null;
    final before = _board.cells.map((row) => row.toList()).toList();
    final result = _board.tryPlace(entry.piece, x: x, y: y);
    if (result == null) return null;
    for (final cell in entry.piece.cells) {
      before[y + cell.y][x + cell.x] = entry.piece.colorId;
    }
    _lastMove = MoveFeedback(result, {
      for (var row = 0; row < BoardLogic.size; row++)
        for (var column = 0; column < BoardLogic.size; column++)
          if (result.clearedRows.contains(row) ||
              result.clearedColumns.contains(column))
            (x: column, y: row): before[row][column],
    });
    _dock[index] = null;
    _dragging = null;
    if (_dock.every((piece) => piece == null)) {
      _round++;
      _refill();
    }
    _checkGameOver();
    _saveRecord();
    notifyListeners();
    return result;
  }

  void reset() {
    _lastMove = null;
    _dragging = null;
    _board.reset();
    _round = 1;
    _refill();
    _checkGameOver();
    _saveRecord();
    notifyListeners();
  }
}
