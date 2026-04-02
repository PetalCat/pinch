import 'package:flutter/material.dart';
import '../theme/tva_colors.dart';

class TickerBar extends StatefulWidget {
  final String label;
  final String text;
  const TickerBar({super.key, this.label = 'SYS', required this.text});

  @override
  State<TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<TickerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: TvaColors.bgInset,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              letterSpacing: 2,
              color: TvaColors.amberDm,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(
                      0.6 - _scrollController.value * 1.6,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    color: TvaColors.txt3,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
