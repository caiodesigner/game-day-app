import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'consumes exactly three pieces before refilling, rejects stale entries',
    () {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      final initial = game.dock;
      expect(initial.length, 3);
      game.place(initial[0]!, 0, 0);
      expect(game.dock[0], isNull);
      expect(game.dock[1], same(initial[1]));
      expect(game.round, 1);
      expect(game.place(initial[0]!, 1, 0), isNull);
      expect(game.place(initial[1]!, 0, 0), isNull);
      expect(game.dock[1], same(initial[1]));
      game.place(initial[1]!, 1, 0);
      game.place(initial[2]!, 2, 0);
      expect(game.round, 2);
      expect(game.dock, everyElement(isNotNull));
      expect(game.dock.any(initial.contains), isFalse);
      expect(game.score, 3);
    },
  );

  test('only one drag is active, cancellation preserves the dock', () {
    final game = GameController(nextPiece: () => Pieces.single);
    addTearDown(game.dispose);
    final entries = game.dock;
    expect(game.beginDrag(entries[0]!), isTrue);
    expect(game.beginDrag(entries[1]!), isFalse);
    expect(game.place(entries[1]!, 0, 0), isNull);
    game.endDrag();
    expect(game.dragging, isNull);
    expect(game.dock, entries);
    expect(game.score, 0);
  });

  test('reset invalidates old drag data and resets board, score and round', () {
    final game = GameController(nextPiece: () => Pieces.single);
    addTearDown(game.dispose);
    final old = game.dock[0]!;
    game.place(old, 0, 0);
    game.beginDrag(game.dock[1]!);
    game.reset();
    expect(game.score, 0);
    expect(game.round, 1);
    expect(game.dragging, isNull);
    expect(game.cells.expand((row) => row), everyElement(0));
    expect(game.place(old, 2, 2), isNull);
  });
}
