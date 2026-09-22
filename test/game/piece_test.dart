import 'package:block_puzzle/game/board_logic.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty, duplicate, negative and unanchored offsets', () {
    for (final cells in <List<({int x, int y})>>[
      [],
      [(x: 0, y: 0), (x: 0, y: 0)],
      [(x: -1, y: 0)],
      [(x: 0, y: -1)],
      [(x: 1, y: 0)],
      [(x: 0, y: 1)],
    ]) {
      expect(() => Piece(cells), throwsArgumentError);
    }
    for (final id in [0, -1]) {
      expect(() => Piece([(x: 0, y: 0)], colorId: id), throwsArgumentError);
    }
  });

  test('copies input and prevents shape mutation', () {
    final cells = [(x: 0, y: 0)];
    final piece = Piece(cells);
    cells.add((x: 1, y: 0));
    expect(piece.blockCount, 1);
    expect(() => piece.cells.clear(), throwsUnsupportedError);
    expect(() => Pieces.all.clear(), throwsUnsupportedError);
  });

  test('catalog includes all 15 shapes and each fits on an empty board', () {
    expect(Pieces.all.length, 15);
    expect(Pieces.all.map((p) => p.blockCount), [
      1,
      4,
      9,
      2,
      3,
      4,
      5,
      2,
      3,
      4,
      5,
      4,
      4,
      4,
      4,
    ]);
    for (final piece in Pieces.all) {
      final board = BoardLogic();
      expect(board.tryPlace(piece, x: 0, y: 0)!.points, piece.blockCount);
      expect(
        board.cells.expand((row) => row).where((v) => v != 0).length,
        piece.blockCount,
      );
    }
  });
}
