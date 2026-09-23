import 'piece.dart';
import 'scoring.dart';

/// Successful move details, including lines before they were cleared.
class PlacementResult {
  PlacementResult._({
    required this.placementPoints,
    required List<int> clearedRows,
    required List<int> clearedColumns,
  }) : clearedRows = List.unmodifiable(clearedRows),
       clearedColumns = List.unmodifiable(clearedColumns);

  final int placementPoints;
  final List<int> clearedRows;
  final List<int> clearedColumns;

  int get clearedLineCount => clearedRows.length + clearedColumns.length;

  /// Triangular bonus: 1 line = 10, 2 = 30, 3 = 60, 4 = 100, etc.
  int get clearPoints => lineClearPoints(clearedLineCount);
  int get points => placementPoints + clearPoints;
}

/// Pure Dart game rules. Coordinates are zero-based: x = column, y = row.
/// Grid access uses cells[y][x]; 0 is empty, positive values are color IDs.
class BoardLogic {
  static const size = 8;

  final List<List<int>> _cells = List.generate(
    size,
    (_) => List.filled(size, 0),
  );
  int _score = 0;

  int get score => _score;

  /// Immutable snapshot; callers cannot bypass placement validation.
  List<List<int>> get cells =>
      List.unmodifiable(_cells.map((row) => List<int>.unmodifiable(row)));

  /// Read-only check, suitable for a drag preview.
  bool canPlace(Piece piece, {required int x, required int y}) {
    for (final cell in piece.cells) {
      final column = x + cell.x;
      final row = y + cell.y;
      if (column < 0 || column >= size || row < 0 || row >= size) {
        return false;
      }
      if (_cells[row][column] != 0) return false;
    }
    return true;
  }

  /// Returns null for an invalid move, leaving both grid and score unchanged.
  /// A valid move places all blocks, clears lines simultaneously and scores once.
  PlacementResult? tryPlace(Piece piece, {required int x, required int y}) {
    if (!canPlace(piece, x: x, y: y)) return null;

    for (final cell in piece.cells) {
      _cells[y + cell.y][x + cell.x] = piece.colorId;
    }

    // Detect both axes before changing any cell, including at intersections.
    final rows = <int>[
      for (var y = 0; y < size; y++)
        if (_cells[y].every((value) => value != 0)) y,
    ];
    final columns = <int>[
      for (var x = 0; x < size; x++)
        if (_cells.every((row) => row[x] != 0)) x,
    ];
    for (final row in rows) {
      _cells[row].fillRange(0, size, 0);
    }
    for (final column in columns) {
      for (final row in _cells) {
        row[column] = 0;
      }
    }

    final result = PlacementResult._(
      placementPoints: piece.blockCount,
      clearedRows: rows,
      clearedColumns: columns,
    );
    _score += result.points;
    return result;
  }

  /// Searches every anchor for every remaining piece, without changing state.
  bool hasAnyMove(Iterable<Piece> pieces) {
    for (final piece in pieces) {
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          if (canPlace(piece, x: x, y: y)) return true;
        }
      }
    }
    return false;
  }

  void reset() {
    for (final row in _cells) {
      row.fillRange(0, size, 0);
    }
    _score = 0;
  }
}
