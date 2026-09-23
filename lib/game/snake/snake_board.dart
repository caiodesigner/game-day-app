import 'dart:math';

typedef SnakeCell = ({int x, int y});

enum SnakeDirection {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const SnakeDirection(this.dx, this.dy);
  final int dx;
  final int dy;
  bool isOpposite(SnakeDirection other) => dx == -other.dx && dy == -other.dy;
}

enum SnakeStep { moved, ate, lost, won }

/// Classic solid-wall Snake. The first segment is the head.
class SnakeBoard {
  SnakeBoard({this.size = 12, Random? random}) : _random = random ?? Random() {
    if (size < 4) throw ArgumentError.value(size, 'size', 'Must be at least 4');
    reset();
  }

  final int size;
  final Random _random;
  final List<SnakeCell> _body = [];
  SnakeCell? _food;
  SnakeDirection _direction = SnakeDirection.right;
  SnakeDirection? _pendingDirection;
  bool _gameOver = false;
  bool _won = false;
  int _foodsEaten = 0;

  List<SnakeCell> get body => List.unmodifiable(_body);
  SnakeCell? get food => _food;
  SnakeDirection get direction => _direction;
  bool get isGameOver => _gameOver;
  bool get hasWon => _won;
  int get foodsEaten => _foodsEaten;
  int get score => _foodsEaten * 10;

  /// Only one turn per tick: rapid taps cannot reverse through the neck.
  bool turn(SnakeDirection direction) {
    if (_gameOver ||
        _pendingDirection != null ||
        direction == _direction ||
        direction.isOpposite(_direction)) {
      return false;
    }
    _pendingDirection = direction;
    return true;
  }

  SnakeStep step() {
    if (_gameOver) return _won ? SnakeStep.won : SnakeStep.lost;
    _direction = _pendingDirection ?? _direction;
    _pendingDirection = null;
    final head = _body.first;
    final next = (x: head.x + _direction.dx, y: head.y + _direction.dy);
    final eats = next == _food;
    // Moving into the current tail is valid when it leaves this tick.
    final occupied = eats ? _body : _body.take(_body.length - 1);
    if (next.x < 0 ||
        next.x >= size ||
        next.y < 0 ||
        next.y >= size ||
        occupied.contains(next)) {
      _gameOver = true;
      return SnakeStep.lost;
    }
    _body.insert(0, next);
    if (!eats) {
      _body.removeLast();
      return SnakeStep.moved;
    }
    _foodsEaten++;
    _placeFood();
    if (_food == null) {
      _won = _gameOver = true;
      return SnakeStep.won;
    }
    return SnakeStep.ate;
  }

  void _placeFood() {
    final occupied = _body.toSet();
    final free = <SnakeCell>[
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          if (!occupied.contains((x: x, y: y))) (x: x, y: y),
    ];
    _food = free.isEmpty ? null : free[_random.nextInt(free.length)];
  }

  void reset() {
    final center = size ~/ 2;
    _body
      ..clear()
      ..addAll([for (var x = center; x >= center - 2; x--) (x: x, y: center)]);
    _direction = SnakeDirection.right;
    _pendingDirection = null;
    _gameOver = _won = false;
    _foodsEaten = 0;
    _placeFood();
  }
}
