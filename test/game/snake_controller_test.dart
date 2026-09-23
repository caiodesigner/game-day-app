import 'dart:async';

import 'package:block_puzzle/game/snake/snake_board.dart';
import 'package:block_puzzle/game/snake/snake_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'high_score_test.dart' show MemoryScores;
import 'snake_test_helpers.dart';

void main() {
  test(
    'requires start, scores food, levels up at 500 and resets with record',
    () async {
      final random = CycleFoodRandom();
      final game = SnakeController(autoTick: false, random: random);
      random.readBody = () => game.body;
      addTearDown(game.dispose);
      game.tick();
      expect(game.body.first, (x: 6, y: 6));
      expect(game.turn(SnakeDirection.up), isFalse);
      game.start();
      final initialInterval = game.moveInterval;
      for (var i = 0; i < 100; i++) {
        game.turn(toward(game.body.first, random.after(game.body.first)));
        game.tick();
        expect(game.score, (i + 1) * 10);
        expect(game.level, 1 + game.score ~/ 500);
      }
      expect(game.level, 3);
      expect(game.moveInterval, lessThan(initialInterval));
      game.reset();
      expect(game.hasStarted, isFalse);
      expect(game.score, 0);
      expect(game.level, 1);
      expect(game.highScore, 1000);
      expect(game.moveInterval, initialInterval);
    },
  );

  testWidgets(
    'timer starts on demand, pauses on interruption and stops on disposal',
    (tester) async {
      final game = SnakeController();
      await tester.pump(const Duration(seconds: 2));
      expect(game.body.first, (x: 6, y: 6));
      game.start();
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.body.first, (x: 7, y: 6));
      game.togglePause();
      expect(game.turn(SnakeDirection.down), isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(game.body.first, (x: 7, y: 6));
      game.togglePause();
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.body.first, (x: 8, y: 6));
      game.setForeground(false);
      game.setForeground(true);
      await tester.pump(const Duration(seconds: 2));
      expect(game.isPaused, isTrue);
      expect(game.body.first, (x: 8, y: 6));
      game.togglePause();
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.body.first, (x: 9, y: 6));
      game.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(game.body.first, (x: 9, y: 6));
    },
  );

  testWidgets('game over stops the timer and reset waits for a new start', (
    tester,
  ) async {
    final game = SnakeController();
    addTearDown(game.dispose);
    game.start();
    await tester.pump(const Duration(seconds: 2));
    expect(game.isGameOver, isTrue);
    final body = game.body;
    await tester.pump(const Duration(seconds: 2));
    expect(game.body, body);
    game.reset();
    await tester.pump(const Duration(seconds: 2));
    expect(game.isGameOver, isFalse);
    expect(game.hasStarted, isFalse);
    expect(game.body.first, (x: 6, y: 6));
  });

  test(
    'delayed record loading, reset and disposal never lose earned points',
    () async {
      final store = MemoryScores()..delay = Completer<void>();
      final random = CycleFoodRandom();
      final game = SnakeController(
        autoTick: false,
        random: random,
        highScoreStore: store,
      );
      random.readBody = () => game.body;
      game.start();
      game.tick();
      game.reset();
      game.dispose();
      store.delay!.complete();
      await game.pendingWrites;
      expect(store.value, 10);
      final reopened = SnakeController(autoTick: false, highScoreStore: store);
      addTearDown(reopened.dispose);
      await reopened.ready;
      expect(reopened.highScore, 10);
      expect(reopened.score, 0);
    },
  );

  test('storage failure allows play and retries after another food', () async {
    final store = MemoryScores()..fail = true;
    final random = CycleFoodRandom();
    final game = SnakeController(
      autoTick: false,
      random: random,
      highScoreStore: store,
    );
    random.readBody = () => game.body;
    addTearDown(game.dispose);
    await game.ready;
    game.start();
    game.tick();
    await game.pendingWrites;
    expect(game.storageError, isTrue);
    store.fail = false;
    game.tick();
    await game.pendingWrites;
    expect(game.storageError, isFalse);
    expect(store.value, 20);
  });
}
