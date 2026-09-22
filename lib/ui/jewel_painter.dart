import 'package:flutter/material.dart';

/// Beveled jewel with a bright upper-left edge and translucent inner facets.
/// Vector painting keeps the same finish sharp at dock and board sizes.
class JewelPainter extends CustomPainter {
  const JewelPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset point(double x, double y) => Offset(x * w, y * h);
    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    final outer = polygon([
      point(.08, 0),
      point(.92, 0),
      point(1, .08),
      point(1, .92),
      point(.92, 1),
      point(.08, 1),
      point(0, .92),
      point(0, .08),
    ]);
    final paint = Paint();
    canvas.save();
    canvas.clipPath(outer);
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, Colors.white, .27)!,
        color,
        Color.lerp(color, Colors.black, .28)!,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawPath(outer, paint);
    paint.shader = null;
    void facet(List<Offset> points, Color shade) {
      paint.color = shade;
      canvas.drawPath(polygon(points), paint);
    }

    facet([
      point(0, 0),
      point(1, 0),
      point(.84, .16),
      point(.16, .16),
    ], Colors.white.withValues(alpha: .48));
    facet([
      point(0, 0),
      point(.16, .16),
      point(.16, .84),
      point(0, 1),
    ], Colors.white.withValues(alpha: .20));
    facet([
      point(1, 0),
      point(1, 1),
      point(.84, .84),
      point(.84, .16),
    ], Colors.black.withValues(alpha: .24));
    facet([
      point(0, 1),
      point(.16, .84),
      point(.84, .84),
      point(1, 1),
    ], Colors.black.withValues(alpha: .32));
    facet([
      point(.16, .16),
      point(.84, .16),
      point(.16, .66),
    ], Colors.white.withValues(alpha: .18));
    facet([
      point(.16, .66),
      point(.84, .16),
      point(.68, .70),
      point(.38, .84),
    ], Colors.white.withValues(alpha: .07));
    facet([
      point(.68, .70),
      point(.84, .16),
      point(.84, .84),
    ], Colors.black.withValues(alpha: .12));
    facet([
      point(.03, .08),
      point(.08, .03),
      point(.24, .18),
      point(.15, .25),
    ], Colors.white.withValues(alpha: .75));
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * .025).clamp(.5, 1.5)
      ..color = Colors.white.withValues(alpha: .24);
    canvas.drawPath(outer, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(JewelPainter oldDelegate) => oldDelegate.color != color;
}
