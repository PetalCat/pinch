import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';

class ClawdSprite extends StatelessWidget {
  final double cellWidth;
  final double cellHeight;
  final Color bodyColor;
  final Color eyeColor;
  final double glowRadius;
  final Color glowColor;
  final bool showEyes;

  const ClawdSprite({
    super.key,
    this.cellWidth = 6.0,
    this.cellHeight = 13.0,
    this.bodyColor = TvaColors.clawd,
    this.eyeColor = TvaColors.bgInset,
    this.glowRadius = 6.0,
    this.glowColor = TvaColors.clawd,
    this.showEyes = true,
  });

  static const grid = [
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 0, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0],
  ];

  @override
  Widget build(BuildContext context) {
    final width = cellWidth * 18;
    final height = cellHeight * 5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: glowRadius,
            spreadRadius: glowRadius / 3,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _ClawdPainter(
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          bodyColor: bodyColor,
          eyeColor: eyeColor,
          showEyes: showEyes,
        ),
      ),
    );
  }
}

class _ClawdPainter extends CustomPainter {
  final double cellWidth;
  final double cellHeight;
  final Color bodyColor;
  final Color eyeColor;
  final bool showEyes;

  _ClawdPainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.bodyColor,
    required this.eyeColor,
    required this.showEyes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = bodyColor;
    final eyePaint = Paint()..color = eyeColor;

    for (var row = 0; row < ClawdSprite.grid.length; row++) {
      for (var col = 0; col < ClawdSprite.grid[row].length; col++) {
        final cell = ClawdSprite.grid[row][col];
        if (cell == 0) continue;

        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );

        if (cell == 1) {
          canvas.drawRect(rect, bodyPaint);
        } else if (cell == 2) {
          // Eye cell: show eye color when eyes visible, body color when blinking
          canvas.drawRect(rect, showEyes ? eyePaint : bodyPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ClawdPainter oldDelegate) {
    return oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.showEyes != showEyes ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight;
  }
}
