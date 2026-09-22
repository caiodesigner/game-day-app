import 'package:block_puzzle/game/board_logic.dart';
import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'searches every anchor and all shapes, including holes and last cell',
    () {
      final board = BoardLogic();
      for (final x in [2, 5]) {
        for (final y in [2, 5]) {
          board.tryPlace(Pieces.single, x: x, y: y);
        }
      }
      final before = board.cells;
      expect(board.hasAnyMove([Pieces.square3]), isFalse);
      expect(board.hasAnyMove([Pieces.square3, Pieces.single]), isTrue);
      expect(board.hasAnyMove([]), isFalse);
      expect(board.cells, before);
      expect(board.score, 4);
    },
  );

  test(
    'remaining dock triggers game over immediately after the last usable piece',
    () {
      var generated = 0;
      final game = GameController(
        nextPiece: () => generated++ < 4 ? Pieces.single : Pieces.square3,
      );
      addTearDown(game.dispose);
      for (final position in [(x: 2, y: 2), (x: 5, y: 2), (x: 2, y: 5)]) {
        expect(
          game.place(
            game.dock.whereType<DockPiece>().first,
            position.x,
            position.y,
          ),
          isNotNull,
        );
        expect(game.isGameOver, isFalse);
      }
      game.place(game.dock[0]!, 5, 5);
      expect(game.isGameOver, isTrue);
      expect(game.score, 4);
      final blocked = game.dock[1]!;
      expect(game.beginDrag(blocked), isFalse);
      expect(game.place(blocked, 0, 0), isNull);
      game.reset();
      expect(game.isGameOver, isFalse);
      expect(game.highScore, 4);
      expect(game.score, 0);
    },
  );

  test('checks freshly generated pieces as soon as a round ends', () {
    var generated = 0;
    final game = GameController(
      nextPiece: () => generated++ < 6 ? Pieces.single : Pieces.square3,
    );
    addTearDown(game.dispose);
    for (final p in [(2, 2), (5, 2), (2, 5), (5, 5), (0, 0), (7, 7)]) {
      expect(
        game.place(game.dock.whereType<DockPiece>().first, p.$1, p.$2),
        isNotNull,
      );
    }
    expect(game.round, 3);
    expect(game.isGameOver, isTrue);
    expect(game.dock, everyElement(isNotNull));
  });

  test('search runs after clearing, so cleared cells allow further moves', () {
    final board = BoardLogic();
    // Block every 3x3 window, then complete the two blocking rows.
    for (final y in [2, 5]) {
      for (final x in [2, 5]) {
        board.tryPlace(Pieces.single, x: x, y: y);
      }
    }
    expect(board.hasAnyMove([Pieces.square3]), isFalse);
    for (final x in [0, 1, 3, 4, 6, 7]) {
      board.tryPlace(Pieces.single, x: x, y: 2);
    }
    expect(board.hasAnyMove([Pieces.square3]), isTrue);
  });
}
