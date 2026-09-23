import 'dart:math';

import 'package:flutter/material.dart';

import '../game/piece.dart';
import 'jewel_painter.dart';

const _palette = [
  Color(0xFF9A7BFF),
  Color(0xFF48D6D2),
  Color(0xFFFFBA62),
  Color(0xFFEF78B1),
  Color(0xFF6EACFF),
];

class JewelCell extends StatelessWidget {
  const JewelCell({
    super.key,
    required this.colorId,
    this.preview,
    this.previewColorId,
  });
  final int colorId;
  final bool? preview;
  final int? previewColorId;

  @override
  Widget build(BuildContext context) {
    final id = preview == true ? (previewColorId ?? colorId) : colorId;
    final color = preview == false
        ? const Color(0xFFE5230B)
        : _palette[((id > 0 ? id : 1) - 1) % _palette.length];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF19192D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E2B44)),
            ),
          ),
          if (colorId != 0 || preview != null)
            Opacity(
              opacity: preview == true ? .38 : 1,
              child: CustomPaint(painter: JewelPainter(color)),
            ),
          if (preview == false)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF3D00), width: 2.5),
              ),
            ),
        ],
      ),
    );
  }
}

class PieceView extends StatelessWidget {
  const PieceView({super.key, required this.piece, required this.cellSize});
  final Piece piece;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final width = piece.cells.map((cell) => cell.x).reduce(max) + 1;
    final height = piece.cells.map((cell) => cell.y).reduce(max) + 1;
    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: cell.x * cellSize,
              top: cell.y * cellSize,
              width: cellSize,
              height: cellSize,
              child: JewelCell(colorId: piece.colorId),
            ),
        ],
      ),
    );
  }
}
