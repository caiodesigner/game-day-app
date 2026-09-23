import 'dart:math';

import 'piece.dart';

/// Larger pieces become more likely at each 500-point milestone.
abstract final class Difficulty {
  static const pointsPerLevel = 500;

  static int levelForScore(int score) => 1 + score ~/ pointsPerLevel;

  static int weight(Piece piece, int level) =>
      1 + (level - 1) * (piece.blockCount - 1);

  static Piece pick(Random random, int level) {
    final total = Pieces.all.fold<int>(
      0,
      (sum, piece) => sum + weight(piece, level),
    );
    var ticket = random.nextInt(total);
    for (final piece in Pieces.all) {
      ticket -= weight(piece, level);
      if (ticket < 0) return piece;
    }
    throw StateError('Invalid piece weights');
  }
}
