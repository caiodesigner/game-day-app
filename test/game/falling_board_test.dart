import 'package:block_puzzle/game/falling/falling_board.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'seven tetrominoes return to their original shape after four rotations',
    () {
      expect(FallingPieces.all.length, 7);
      for (final shape in FallingPieces.all) {
        expect(shape.blockCount, 4);
        var rotated = shape;
        for (var i = 0; i < 4; i++) {
          rotated = FallingPieces.rotate(rotated);
        }
        expect(rotated.cells.toSet(), shape.cells.toSet());
        expect(rotated.colorId, shape.colorId);
      }
    },
  );

  test('rejects bounds and overlaps without changing the board', () {
    final board = FallingBoard();
    expect(board.lock(Pieces.square2, -1, 0), isNull);
    expect(board.lock(Pieces.square2, 7, 0), isNull);
    expect(board.lock(Pieces.square2, 0, 15), isNull);
    expect(board.lock(Pieces.square2, 0, -1), isNull);
    expect(board.lock(Pieces.square2, 0, 14)!.points, 4);
    final snapshot = board.cells;
    expect(board.lock(Pieces.square2, 1, 13), isNull);
    expect(board.cells, snapshot);
    expect(() => snapshot[0][0] = 1, throwsUnsupportedError);
  });

  for (var count = 1; count <= 4; count++) {
    test('clears $count rows together, applies shared bonus and gravity', () {
      final board = FallingBoard();
      board.lock(Piece([(x: 0, y: 0)], colorId: 5), 2, 10);
      for (var y = 16 - count; y < 16; y++) {
        for (var x = 0; x < 7; x++) {
          board.lock(Pieces.single, x, y);
        }
      }
      final piece = Piece([for (var y = 0; y < count; y++) (x: 0, y: y)]);
      final result = board.lock(piece, 7, 16 - count)!;
      expect(result.rows, [for (var y = 16 - count; y < 16; y++) y]);
      expect(result.points, count + [10, 30, 60, 100][count - 1]);
      expect(board.cells[10 + count][2], 5);
      expect(
        board.cells.expand((row) => row).where((cell) => cell != 0).length,
        1,
      );
    });
  }

  test('full columns remain; only rows clear', () {
    final board = FallingBoard();
    for (var y = 0; y < 16; y++) {
      expect(board.lock(Pieces.single, 0, y)!.rows, isEmpty);
    }
    expect(board.cells.every((row) => row[0] != 0), isTrue);
    board.reset();
    expect(board.cells.expand((row) => row), everyElement(0));
  });
}
