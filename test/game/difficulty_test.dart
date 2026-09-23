import 'dart:math';

import 'package:block_puzzle/game/difficulty.dart';
import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

class TicketRandom implements Random {
  TicketRandom(this.ticket);
  final int ticket;

  @override
  int nextInt(int max) {
    expect(ticket, lessThan(max));
    return ticket;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  test('level increases at every 500 points without a level cap', () {
    for (final (score, level) in [
      (0, 1),
      (499, 1),
      (500, 2),
      (999, 2),
      (1000, 3),
      (10000, 21),
    ]) {
      expect(Difficulty.levelForScore(score), level);
    }
  });

  test('weighted draw keeps all shapes and favors larger pieces over time', () {
    double previousAverage = 0;
    for (final level in [1, 2, 3, 10]) {
      final counts = <Piece, int>{};
      final total = Pieces.all.fold<int>(
        0,
        (sum, piece) => sum + Difficulty.weight(piece, level),
      );
      for (var ticket = 0; ticket < total; ticket++) {
        final piece = Difficulty.pick(TicketRandom(ticket), level);
        counts.update(piece, (count) => count + 1, ifAbsent: () => 1);
      }
      expect(counts.length, Pieces.all.length);
      if (level == 1) expect(counts.values.toSet(), {1});
      final average =
          counts.entries.fold<int>(
            0,
            (sum, entry) => sum + entry.key.blockCount * entry.value,
          ) /
          total;
      expect(average, greaterThan(previousAverage));
      previousAverage = average;
    }
  });

  test(
    'moves update difficulty across milestones and reset returns to level 1',
    () {
      final game = GameController(nextPiece: () => Pieces.single);
      addTearDown(game.dispose);
      var move = 0;
      while (game.score < 1000) {
        final before = game.score;
        final entry = game.dock.whereType<DockPiece>().first;
        expect(game.place(entry, move % 8, 0), isNotNull);
        move++;
        expect(game.difficultyLevel, 1 + game.score ~/ 500);
        if (before < 500 && game.score >= 500) {
          expect(game.difficultyLevel, 2);
        }
      }
      expect(game.difficultyLevel, 3);
      game.reset();
      expect(game.difficultyLevel, 1);
    },
  );
}
