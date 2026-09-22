/// Immutable occupied offsets, relative to the piece's top-left corner.
/// x is the column and y is the row; empty parts of a shape are omitted.
class Piece {
  Piece(Iterable<({int x, int y})> cells, {this.colorId = 1})
    : cells = List.unmodifiable(cells) {
    if (colorId <= 0) {
      throw ArgumentError.value(colorId, 'colorId', 'Must be positive');
    }
    if (this.cells.isEmpty ||
        this.cells.any((cell) => cell.x < 0 || cell.y < 0) ||
        this.cells.toSet().length != this.cells.length ||
        !this.cells.any((cell) => cell.x == 0) ||
        !this.cells.any((cell) => cell.y == 0)) {
      throw ArgumentError('Use unique, nonnegative offsets anchored at x/y 0');
    }
  }

  final List<({int x, int y})> cells;
  final int colorId;

  int get blockCount => cells.length;
}

/// Fixed orientations for the initial set. Rotation is not a player action.
abstract final class Pieces {
  static Piece _rectangle(int width, int height) => Piece([
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++) (x: x, y: y),
  ]);

  static final single = _rectangle(1, 1);
  static final square2 = _rectangle(2, 2);
  static final square3 = _rectangle(3, 3);
  static final horizontalLines = List<Piece>.unmodifiable([
    for (var length = 2; length <= 5; length++) _rectangle(length, 1),
  ]);
  static final verticalLines = List<Piece>.unmodifiable([
    for (var length = 2; length <= 5; length++) _rectangle(1, length),
  ]);
  static final l = Piece([
    (x: 0, y: 0),
    (x: 0, y: 1),
    (x: 0, y: 2),
    (x: 1, y: 2),
  ]);
  static final j = Piece([
    (x: 1, y: 0),
    (x: 1, y: 1),
    (x: 0, y: 2),
    (x: 1, y: 2),
  ]);
  static final t = Piece([
    (x: 0, y: 0),
    (x: 1, y: 0),
    (x: 2, y: 0),
    (x: 1, y: 1),
  ]);
  static final z = Piece([
    (x: 0, y: 0),
    (x: 1, y: 0),
    (x: 1, y: 1),
    (x: 2, y: 1),
  ]);
  static final all = List<Piece>.unmodifiable([
    single,
    square2,
    square3,
    ...horizontalLines,
    ...verticalLines,
    l,
    j,
    t,
    z,
  ]);
}
