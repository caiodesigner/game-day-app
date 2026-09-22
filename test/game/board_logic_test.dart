import 'package:block_puzzle/game/board_logic.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BoardLogic board;
  setUp(() => board = BoardLogic());

  void placeSingle(int x, int y) {
    expect(board.tryPlace(Pieces.single, x: x, y: y), isNotNull);
  }

  test('starts with 64 empty cells and zero score', () {
    expect(board.cells.length, 8);
    expect(board.cells.every((row) => row.length == 8), isTrue);
    expect(board.cells.expand((row) => row), everyElement(0));
    expect(board.score, 0);
  });

  test('uses x as column, y as row and preserves color IDs', () {
    final piece = Piece([(x: 0, y: 0), (x: 1, y: 0)], colorId: 4);
    final result = board.tryPlace(piece, x: 5, y: 2)!;
    expect(board.cells[2][5], 4);
    expect(board.cells[2][6], 4);
    expect(board.cells[5][2], 0);
    expect(result.placementPoints, 2);
    expect(result.clearPoints, 0);
    expect(board.score, 2);
  });

  test('accepts an exact fit at the bottom-right edge', () {
    expect(board.tryPlace(Pieces.square3, x: 5, y: 5)!.points, 9);
    expect(board.cells[7][7], 1);
    expect(board.cells.expand((row) => row).where((v) => v != 0).length, 9);
  });

  test('rejects all boundaries without partially inserting a piece', () {
    for (final position in [
      (x: -1, y: 0),
      (x: 0, y: -1),
      (x: 7, y: 0),
      (x: 0, y: 7),
      (x: 8, y: 0),
      (x: 0, y: 8),
    ]) {
      expect(
        board.canPlace(Pieces.square2, x: position.x, y: position.y),
        isFalse,
      );
      expect(
        board.tryPlace(Pieces.square2, x: position.x, y: position.y),
        isNull,
      );
      expect(board.cells.expand((row) => row), everyElement(0));
      expect(board.score, 0);
    }
  });

  test(
    'overlap at the last block leaves earlier cells and score unchanged',
    () {
      placeSingle(3, 3);
      final before = board.cells;
      expect(board.tryPlace(Pieces.square2, x: 2, y: 2), isNull);
      expect(board.cells, before);
      expect(board.score, 1);
    },
  );

  test('shape gaps may overlap existing blocks', () {
    placeSingle(1, 0); // Empty part of the L bounding box.
    expect(board.canPlace(Pieces.l, x: 0, y: 0), isTrue);
    expect(board.tryPlace(Pieces.l, x: 0, y: 0)!.points, 4);
    expect(board.cells[0][1], 1);
    expect(board.score, 5);
  });

  test('preview neither places blocks nor changes score', () {
    final before = board.cells;
    expect(board.canPlace(Pieces.t, x: 1, y: 2), isTrue);
    expect(board.cells, before);
    expect(board.score, 0);
  });

  for (final vertical in [false, true]) {
    test(
      'clears one ${vertical ? 'column' : 'row'} and preserves other cells',
      () {
        placeSingle(6, 6);
        for (var i = 0; i < 7; i++) {
          placeSingle(vertical ? 0 : i, vertical ? i : 0);
        }
        final result = board.tryPlace(
          Pieces.single,
          x: vertical ? 0 : 7,
          y: vertical ? 7 : 0,
        )!;
        expect(result.clearedRows, vertical ? isEmpty : [0]);
        expect(result.clearedColumns, vertical ? [0] : isEmpty);
        expect(result.points, 11);
        expect(board.score, 19);
        expect(board.cells[6][6], 1);
        expect(board.cells.expand((row) => row).where((v) => v != 0).length, 1);
      },
    );
  }

  test('clears intersecting row and column simultaneously', () {
    for (var i = 1; i < 8; i++) {
      placeSingle(i, 0);
      placeSingle(0, i);
    }
    final result = board.tryPlace(Pieces.single, x: 0, y: 0)!;
    expect(result.clearedRows, [0]);
    expect(result.clearedColumns, [0]);
    expect(result.clearPoints, 30);
    expect(result.points, 31);
    expect(board.score, 45);
    expect(board.cells.expand((row) => row), everyElement(0));
    expect(() => result.clearedRows.add(3), throwsUnsupportedError);
    expect(() => result.clearedColumns.add(3), throwsUnsupportedError);
  });

  for (final count in [2, 3, 4]) {
    test('clears $count parallel rows with the expected combo', () {
      for (var y = 0; y < count; y++) {
        for (var x = 0; x < 7; x++) {
          placeSingle(x, y);
        }
      }
      final result = board.tryPlace(
        Pieces.verticalLines[count - 2],
        x: 7,
        y: 0,
      )!;
      expect(result.clearedRows, List.generate(count, (i) => i));
      expect(result.clearedColumns, isEmpty);
      expect(result.clearPoints, {2: 30, 3: 60, 4: 100}[count]);
      expect(result.placementPoints, count);
      expect(board.score, 8 * count + result.clearPoints);
      expect(board.cells.expand((row) => row), everyElement(0));
      // A later move cannot award points again for the cleared lines.
      expect(board.tryPlace(Pieces.single, x: 7, y: 7)!.points, 1);
    });
  }

  test('clears multiple rows and columns in the same move', () {
    for (var y = 0; y < 2; y++) {
      for (var x = 2; x < 8; x++) {
        placeSingle(x, y);
      }
    }
    for (var x = 0; x < 2; x++) {
      for (var y = 2; y < 8; y++) {
        placeSingle(x, y);
      }
    }
    final result = board.tryPlace(Pieces.square2, x: 0, y: 0)!;
    expect(result.clearedRows, [0, 1]);
    expect(result.clearedColumns, [0, 1]);
    expect(result.points, 104);
    expect(board.score, 128);
    expect(board.cells.expand((row) => row), everyElement(0));
  });

  test('board snapshots are immutable and do not change after moves', () {
    final snapshot = board.cells;
    expect(() => snapshot[0][0] = 5, throwsUnsupportedError);
    expect(() => snapshot.add([]), throwsUnsupportedError);
    placeSingle(0, 0);
    expect(snapshot[0][0], 0);
  });

  test('reset clears score and every cell and permits a new game', () {
    board.tryPlace(Pieces.square3, x: 3, y: 3);
    board.reset();
    expect(board.score, 0);
    expect(board.cells.expand((row) => row), everyElement(0));
    expect(board.tryPlace(Pieces.square3, x: 3, y: 3)!.points, 9);
  });
}
