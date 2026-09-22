import 'dart:async';

import 'package:block_puzzle/game/game_controller.dart';
import 'package:block_puzzle/game/piece.dart';
import 'package:block_puzzle/storage/high_score_store.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryScores implements HighScoreStore {
  int value = 0;
  bool fail = false;
  Completer<void>? delay;
  final writes = <int>[];
  @override
  Future<int> read() async {
    await delay?.future;
    if (fail) throw StateError('storage unavailable');
    return value;
  }

  @override
  Future<void> write(int score) async {
    if (fail) throw StateError('storage unavailable');
    value = score;
    writes.add(score);
  }
}

void main() {
  test(
    'loads record and never lowers it on a smaller score or reset',
    () async {
      final store = MemoryScores()..value = 100;
      final game = GameController(
        highScoreStore: store,
        nextPiece: () => Pieces.single,
      );
      addTearDown(game.dispose);
      await game.ready;
      expect(game.highScore, 100);
      game.place(game.dock[0]!, 0, 0);
      game.reset();
      await game.pendingWrites;
      expect(store.value, 100);
      expect(store.writes, isEmpty);
      expect(game.highScore, 100);
    },
  );

  test(
    'saves immediately, restores in a new controller, and survives reset',
    () async {
      final store = MemoryScores();
      final game = GameController(
        highScoreStore: store,
        nextPiece: () => Pieces.square2,
      );
      game.place(game.dock[0]!, 0, 0);
      game.place(game.dock[1]!, 2, 0);
      expect(game.highScore, 8);
      game.reset();
      await game.pendingWrites;
      game.dispose();
      final reopened = GameController(highScoreStore: store);
      addTearDown(reopened.dispose);
      await reopened.ready;
      expect(reopened.highScore, 8);
      expect(reopened.score, 0);
    },
  );

  test('late reads cannot erase points earned while loading', () async {
    final store = MemoryScores()..delay = Completer<void>();
    final game = GameController(
      highScoreStore: store,
      nextPiece: () => Pieces.square3,
    );
    addTearDown(game.dispose);
    game.place(game.dock[0]!, 0, 0);
    expect(game.highScore, 9);
    store.delay!.complete();
    await game.pendingWrites;
    expect(game.highScore, 9);
    expect(store.value, 9);
  });

  test('storage failure does not block play and later writes retry', () async {
    final store = MemoryScores()..fail = true;
    final game = GameController(
      highScoreStore: store,
      nextPiece: () => Pieces.single,
    );
    addTearDown(game.dispose);
    await game.ready;
    game.place(game.dock[0]!, 0, 0);
    await game.pendingWrites;
    expect(game.score, 1);
    expect(game.storageError, isTrue);
    store.fail = false;
    game.place(game.dock[1]!, 1, 0);
    await game.pendingWrites;
    expect(game.storageError, isFalse);
    expect(store.value, 2);
  });

  test('pending work completes safely after disposal', () async {
    final store = MemoryScores()..delay = Completer<void>();
    final game = GameController(
      highScoreStore: store,
      nextPiece: () => Pieces.single,
    );
    game.place(game.dock[0]!, 0, 0);
    game.dispose();
    store.delay!.complete();
    await game.pendingWrites;
    expect(store.value, 1);
  });
}
