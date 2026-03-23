import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class Ticker extends StatefulWidget {
  final String text;

  const Ticker({
    super.key,
    this.text =
        'SESSION FIX-AUTH ACTIVE — MODEL: OPUS 4.6 — STATUS: NOMINAL — PERMISSION MODE: DEFAULT',
  });

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _tickerStyle = TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontFamilyFallback: ['monospace'],
    fontSize: 9,
    letterSpacing: 1,
    color: TvaColors.txt3,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _tickerStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final textWidth = _measureTextWidth(widget.text);

    return Container(
      height: 24,
      color: TvaColors.bgInset,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'SYS',
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontFamilyFallback: ['monospace'],
                fontSize: 9,
                letterSpacing: 2,
                color: TvaColors.amberDm,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth;
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(
                          lerpDouble(
                              containerWidth, -textWidth, _controller.value)!,
                          0,
                        ),
                        child: Text(
                          widget.text,
                          style: _tickerStyle,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
