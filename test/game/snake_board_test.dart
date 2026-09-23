import 'dart:math';

import 'package:block_puzzle/game/snake/snake_board.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snake_test_helpers.dart';

void main() {
  test(
    'starts with three segments, immutable body and food in a free cell',
    () {
      final board = SnakeBoard(random: Random(7));
      expect(board.body.length, 3);
      expect(board.direction, SnakeDirection.right);
      expect(board.body.contains(board.food), isFalse);
      expect(board.score, 0);
      expect(() => board.body.clear(), throwsUnsupportedError);
    },
  );

  test('moves without growth and rejects direct or rapid reversal', () {
    final board = SnakeBoard(random: Random(7));
    expect(board.turn(SnakeDirection.left), isFalse);
    expect(board.turn(SnakeDirection.up), isTrue);
    expect(board.turn(SnakeDirection.left), isFalse);
    expect(board.direction, SnakeDirection.right);
    expect(board.step(), SnakeStep.moved);
    expect(board.body.first, (x: 6, y: 5));
    expect(board.body.length, 3);
    expect(board.direction, SnakeDirection.up);
    expect(board.turn(SnakeDirection.left), isTrue);
    board.step();
    expect(board.body.first, (x: 5, y: 5));
  });

  test('food grows the snake exactly once and respawns outside the body', () {
    final random = CycleFoodRandom();
    final board = SnakeBoard(random: random);
    random.readBody = () => board.body;
    expect(board.food, (x: 7, y: 6));
    expect(board.step(), SnakeStep.ate);
    expect(board.body.length, 4);
    expect(board.score, 10);
    expect(board.food, (x: 8, y: 6));
    expect(board.body.contains(board.food), isFalse);
  });

  test('hitting any wall ends play without wrapping or changing score', () {
    for (final direction in SnakeDirection.values) {
      final board = SnakeBoard(random: Random(9));
      if (direction == SnakeDirection.left) {
        board.turn(SnakeDirection.up);
        board.step();
      }
      board.turn(direction);
      for (var i = 0; i < 13 && !board.isGameOver; i++) {
        board.step();
      }
      expect(board.isGameOver, isTrue);
      expect(board.hasWon, isFalse);
      final snapshot = board.body;
      final score = board.score;
      expect(board.step(), SnakeStep.lost);
      expect(board.body, snapshot);
      expect(board.score, score);
      expect(board.turn(SnakeDirection.up), isFalse);
    }
  });

  test('can enter a departing tail but cannot collide with the body', () {
    final random = CycleFoodRandom();
    final board = SnakeBoard(random: random);
    random.readBody = () => board.body;
    board.step(); // length 4, head (7,6).
    board.turn(SnakeDirection.up);
    board.step();
    board.turn(SnakeDirection.left);
    board.step();
    board.turn(SnakeDirection.down);
    expect(board.step(), SnakeStep.moved); // (6,6), formerly the tail.
    expect(board.isGameOver, isFalse);

    final otherRandom = CycleFoodRandom();
    final other = SnakeBoard(random: otherRandom);
    otherRandom.readBody = () => other.body;
    for (var i = 0; i < 3; i++) {
      other.step();
    } // length 6.
    other.turn(SnakeDirection.up);
    other.step();
    other.turn(SnakeDirection.left);
    other.step();
    other.turn(SnakeDirection.down);
    expect(other.step(), SnakeStep.lost);
  });

  test('filling the entire board wins without looping while spawning food', () {
    final random = CycleFoodRandom();
    final board = SnakeBoard(random: random);
    random.readBody = () => board.body;
    for (var i = 0; i < 141; i++) {
      board.turn(toward(board.body.first, random.after(board.body.first)));
      final result = board.step();
      expect(result, i == 140 ? SnakeStep.won : SnakeStep.ate);
      expect(board.body.toSet().length, board.body.length);
    }
    expect(board.hasWon, isTrue);
    expect(board.isGameOver, isTrue);
    expect(board.food, isNull);
    expect(board.score, 1410);
    expect(board.body.length, 144);
    board.reset();
    expect(board.score, 0);
    expect(board.body.length, 3);
    expect(board.hasWon, isFalse);
    expect(board.isGameOver, isFalse);
    expect(board.food, isNotNull);
  });
}
