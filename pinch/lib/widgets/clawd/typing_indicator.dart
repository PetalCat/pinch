import 'package:flutter/material.dart';
import '../../theme/tva_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0.0),
            const SizedBox(width: 3),
            _dot(0.2),
            const SizedBox(width: 3),
            _dot(0.4),
          ],
        );
      },
    );
  }

  Widget _dot(double delay) {
    // Each dot pulses: 0.3 opacity baseline, 1.0 at peak
    // Stagger by delay fraction of the cycle
    final adjusted = (_controller.value + delay) % 1.0;
    final opacity = adjusted < 0.5
        ? 0.3 + 0.7 * (adjusted / 0.5)
        : 0.3 + 0.7 * (1.0 - (adjusted - 0.5) / 0.5);
    // Snap to steps for pixel feel
    final snapped = (opacity * 4).round() / 4.0;

    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: TvaColors.amber.withValues(alpha: snapped),
      ),
    );
  }
}
