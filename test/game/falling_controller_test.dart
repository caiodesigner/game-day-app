import 'dart:async';
import 'dart:math';

import 'package:block_puzzle/game/falling/falling_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

import 'high_score_test.dart' show MemoryScores;

void main() {
  FallingController create({Piece? piece, MemoryScores? store}) {
    final game = FallingController(
      autoStart: false,
      nextPiece: () => piece ?? Pieces.square2,
      highScoreStore: store,
    );
    addTearDown(game.dispose);
    return game;
  }

  test('gravity, ghost and hard drop award points only on locking', () {
    final game = create();
    expect(game.landingY, 14);
    game.stepDown();
    expect(game.y, 1);
    expect(game.score, 0);
    game.drop();
    expect(game.score, 4);
    expect(game.lockedPieces, 1);
    expect(game.cells[14][3], isPositive);
    expect(game.y, 0);
    expect(game.landingY, 12);
    for (var i = 0; i < 13; i++) {
      game.stepDown();
    }
    expect(game.score, 8);
    expect(game.lockedPieces, 2);
  });

  test('horizontal boundaries and wall kicks preserve valid placement', () {
    final game = create(piece: Pieces.horizontalLines[2]);
    expect(game.rotate(), isTrue);
    while (game.move(1)) {}
    expect(game.x, 7);
    expect(game.rotate(), isTrue);
    expect(game.x, 4);
    expect(game.move(1), isFalse);
    while (game.move(-1)) {}
    expect(game.x, 0);
    expect(game.move(-1), isFalse);
    for (var i = 0; i < 15; i++) {
      game.stepDown();
    }
    final previous = game.active;
    expect(game.rotate(), isFalse); // No space below for vertical I.
    expect(game.active, same(previous));
    expect(game.score, 0);
  });

  test('rotation cannot overlap locked blocks', () {
    var generated = 0;
    final game = FallingController(
      autoStart: false,
      nextPiece: () =>
          generated++ < 3 ? Pieces.square2 : Pieces.horizontalLines[2],
    );
    addTearDown(game.dispose);
    for (final target in [0, 2, 4]) {
      while (game.x > target) {
        expect(game.move(-1), isTrue);
      }
      while (game.x < target) {
        expect(game.move(1), isTrue);
      }
      game.drop();
    }
    for (var i = 0; i < 12; i++) {
      game.stepDown();
    }
    final previous = game.active;
    expect(game.rotate(), isFalse);
    expect(game.active, same(previous));
    expect(game.y, 12);
    expect(game.score, 12);
  });

  test('seven-piece bags contain each shape once', () {
    final game = FallingController(autoStart: false, random: Random(42));
    addTearDown(game.dispose);
    final shapes = <String>{};
    for (var i = 0; i < 7; i++) {
      expect(game.isGameOver, isFalse);
      final cells = game.active.cells.map((c) => '${c.x},${c.y}').toList()
        ..sort();
      shapes.add(cells.join(';'));
      while (game.move(i.isEven ? -1 : 1)) {}
      game.drop();
    }
    expect(shapes.length, 7);
  });

  test(
    'clears rows, levels up every 500 points, resets and retains record',
    () {
      final game = create();
      final firstInterval = game.fallInterval;
      var target = 0;
      while (game.score < 1000) {
        while (game.x < target) {
          expect(game.move(1), isTrue);
        }
        while (game.x > target) {
          expect(game.move(-1), isTrue);
        }
        game.drop();
        target = (target + 2) % 8;
        expect(game.level, 1 + game.score ~/ 500);
        expect(game.isGameOver, isFalse);
      }
      expect(game.clearedLines, greaterThan(0));
      expect(game.level, 3);
      expect(game.fallInterval, lessThan(firstInterval));
      final record = game.highScore;
      game.reset();
      expect(game.level, 1);
      expect(game.score, 0);
      expect(game.clearedLines, 0);
      expect(game.fallInterval, firstInterval);
      expect(game.highScore, record);
    },
  );

  test('blocked spawn ends game; all input stops until reset', () {
    final game = create();
    for (var i = 0; i < 8; i++) {
      game.drop();
    }
    expect(game.isGameOver, isTrue);
    expect(game.score, 32);
    expect(game.move(1), isFalse);
    expect(game.rotate(), isFalse);
    game.drop();
    game.stepDown();
    expect(game.score, 32);
    game.reset();
    expect(game.isGameOver, isFalse);
    expect(game.cells.expand((row) => row), everyElement(0));
  });

  testWidgets('timer pauses, resumes, restarts and stops on dispose', (
    tester,
  ) async {
    final game = FallingController(nextPiece: () => Pieces.square2);
    await tester.pump(const Duration(milliseconds: 800));
    expect(game.y, 1);
    game.togglePause();
    game.drop();
    expect(game.move(1), isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(game.y, 1);
    game.togglePause();
    await tester.pump(const Duration(milliseconds: 800));
    expect(game.y, 2);
    game.setForeground(false);
    game.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect(game.isPaused, isTrue);
    expect(game.y, 2);
    game.reset();
    await tester.pump(const Duration(milliseconds: 800));
    expect(game.y, 1);
    game.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(game.y, 1);
  });

  test(
    'record loads, saves through disposal, and recovers from storage errors',
    () async {
      final store = MemoryScores()..fail = true;
      final game = FallingController(
        autoStart: false,
        nextPiece: () => Pieces.square2,
        highScoreStore: store,
      );
      await game.ready;
      expect(game.storageError, isTrue);
      game.drop();
      await game.pendingWrites;
      expect(game.storageError, isTrue);
      store.fail = false;
      game.drop();
      game.dispose();
      await game.pendingWrites;
      expect(store.value, 8);
      final reopened = create(store: store);
      await reopened.ready;
      expect(reopened.highScore, 8);
      expect(reopened.score, 0);
    },
  );

  test(
    'late record load preserves newer score and reset cannot lower record',
    () async {
      final store = MemoryScores()..delay = Completer<void>();
      final game = create(store: store);
      game.drop();
      game.reset();
      store.delay!.complete();
      await game.pendingWrites;
      expect(game.highScore, 4);
      expect(store.value, 4);
    },
  );
}
