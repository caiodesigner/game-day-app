import 'dart:math';

import '../piece.dart';
import '../scoring.dart';

abstract final class FallingPieces {
  static final all = List<Piece>.unmodifiable([
    Pieces.horizontalLines[2], // I
    Pieces.square2, // O
    Pieces.t,
    Pieces.l,
    Pieces.j,
    Pieces.z,
    Piece([(x: 1, y: 0), (x: 2, y: 0), (x: 0, y: 1), (x: 1, y: 1)]), // S
  ]);

  static Piece rotate(Piece piece) {
    final height = piece.cells.map((cell) => cell.y).reduce(max) + 1;
    return Piece([
      for (final cell in piece.cells) (x: height - 1 - cell.y, y: cell.x),
    ], colorId: piece.colorId);
  }
}

class FallingPlacement {
  FallingPlacement(this.blocks, Iterable<int> rows)
    : rows = List.unmodifiable(rows);
  final int blocks;
  final List<int> rows;
  int get points => blocks + lineClearPoints(rows.length);
}

/// Only horizontal lines clear. Remaining rows fall to fill their spaces.
class FallingBoard {
  static const width = 8;
  static const height = 16;
  final List<List<int>> _cells = List.generate(
    height,
    (_) => List.filled(width, 0),
  );

  List<List<int>> get cells =>
      List.unmodifiable(_cells.map((row) => List<int>.unmodifiable(row)));

  bool fits(Piece piece, int x, int y) => piece.cells.every((cell) {
    final column = x + cell.x;
    final row = y + cell.y;
    return column >= 0 &&
        column < width &&
        row >= 0 &&
        row < height &&
        _cells[row][column] == 0;
  });

  FallingPlacement? lock(Piece piece, int x, int y) {
    if (!fits(piece, x, y)) return null;
    for (final cell in piece.cells) {
      _cells[y + cell.y][x + cell.x] = piece.colorId;
    }
    final rows = [
      for (var row = 0; row < height; row++)
        if (_cells[row].every((cell) => cell != 0)) row,
    ];
    final remaining = [
      for (var row = 0; row < height; row++)
        if (!rows.contains(row)) _cells[row],
    ];
    _cells
      ..clear()
      ..addAll(List.generate(rows.length, (_) => List.filled(width, 0)))
      ..addAll(remaining);
    return FallingPlacement(piece.blockCount, rows);
  }

  void reset() {
    for (final row in _cells) {
      row.fillRange(0, width, 0);
    }
  }
}
