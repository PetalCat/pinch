import 'package:flutter/material.dart';
import '../theme/tva_colors.dart';

class PanelCorners extends StatefulWidget {
  final Widget child;
  const PanelCorners({super.key, required this.child});

  @override
  State<PanelCorners> createState() => _PanelCornersState();
}

class _PanelCornersState extends State<PanelCorners>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Scan line
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ScanLinePainter(_scanController.value),
                );
              },
            ),
          ),
        ),
        // Corners
        const Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
        const Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
        const Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
        const Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TvaColors.brdAc
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0x40D4A428), // amber-br at ~25% opacity
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 1));
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
