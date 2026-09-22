import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'visual feedback retains colors at intersections without duplicate cells',
    () {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      final colors = <({int x, int y}), int>{};
      void place(int x, int y) {
        final entry = game.dock.whereType<DockPiece>().first;
        colors[(x: x, y: y)] = entry.piece.colorId;
        game.place(entry, x, y);
      }

      for (var i = 1; i < 8; i++) {
        place(i, 0);
        place(0, i);
      }
      place(0, 0);
      final feedback = game.lastMove!;
      expect(feedback.clearedCells, colors);
      expect(feedback.clearedCells.length, 15);
      expect(feedback.result.clearedLineCount, 2);
      expect(feedback.result.points, 31);
      expect(() => feedback.clearedCells.clear(), throwsUnsupportedError);
      expect(game.cells.expand((r) => r), everyElement(0));
      game.place(game.dock.whereType<DockPiece>().first, -1, 0);
      expect(game.lastMove, same(feedback));
      game.reset();
      expect(game.lastMove, isNull);
      expect(feedback.clearedCells.length, 15);
    },
  );
}
