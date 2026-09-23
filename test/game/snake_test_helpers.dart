import 'dart:math';

import 'package:block_puzzle/game/snake/snake_board.dart';

/// Places food on a Hamiltonian cycle so tests can reach every length safely.
class CycleFoodRandom implements Random {
  CycleFoodRandom({this.size = 12});
  final int size;
  List<SnakeCell> Function()? readBody;
  List<SnakeCell> get cycle => [
    for (var x = 0; x < size; x++) (x: x, y: 0),
    for (var y = 1; y < size; y++)
      if (y.isOdd)
        for (var x = size - 1; x >= 1; x--) (x: x, y: y)
      else
        for (var x = 1; x < size; x++) (x: x, y: y),
    for (var y = size - 1; y > 0; y--) (x: 0, y: y),
  ];

  SnakeCell after(SnakeCell cell) =>
      cycle[(cycle.indexOf(cell) + 1) % cycle.length];

  @override
  int nextInt(int max) {
    final body =
        readBody?.call() ??
        [for (var x = size ~/ 2; x >= size ~/ 2 - 2; x--) (x: x, y: size ~/ 2)];
    final free = [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          if (!body.contains((x: x, y: y))) (x: x, y: y),
    ];
    final index = free.indexOf(after(body.first));
    if (index < 0 || index >= max) throw StateError('Invalid food fixture');
    return index;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

SnakeDirection toward(SnakeCell from, SnakeCell to) {
  if (to.x > from.x) return SnakeDirection.right;
  if (to.x < from.x) return SnakeDirection.left;
  return to.y > from.y ? SnakeDirection.down : SnakeDirection.up;
}
