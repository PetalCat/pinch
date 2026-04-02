import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_session_provider.dart';
import '../providers/clawd_state_provider.dart';
import '../providers/connection_provider.dart';
import '../theme/tva_colors.dart';
import 'clawd/clawd_animator.dart';

String _formatWithCommas(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class Masthead extends ConsumerWidget {
  const Masthead({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clawdState = ref.watch(clawdStateProvider);
    final meta = ref.watch(sessionMetaProvider);
    final connStatus = ref.watch(connectionStatusProvider);
    const mono = TextStyle(fontFamily: 'IBMPlexMono');

    // Connection status display
    final (Color statusColor, String statusText) = connStatus.when(
      data: (status) => switch (status) {
        ConnectionStatus.connected => (TvaColors.greenBr, 'CONNECTED'),
        ConnectionStatus.connecting => (TvaColors.amber, 'CONNECTING...'),
        ConnectionStatus.error => (TvaColors.rust, 'DISCONNECTED'),
        ConnectionStatus.disconnected => (TvaColors.rust, 'DISCONNECTED'),
      },
      loading: () => (TvaColors.amber, 'CONNECTING...'),
      error: (_, __) => (TvaColors.rust, 'DISCONNECTED'),
    );

    // Format elapsed as HH:MM:SS
    final elapsed = meta.elapsed;
    final hh = elapsed.inHours.toString().padLeft(2, '0');
    final mm = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final clockText = '$hh:$mm:$ss';

    return Container(
      height: 52,
      color: TvaColors.bgInset,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ClawdAnimator(
            state: clawdState,
            cellWidth: 3,
            cellHeight: 7,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PINCH',
                style: mono.copyWith(
                  color: TvaColors.clawd,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontSize: 14,
                ),
              ),
              Text(
                'Claude Code in a Pinch!',
                style: mono.copyWith(
                  color: TvaColors.txt3,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tokens
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOKENS',
                    style: mono.copyWith(
                      color: TvaColors.txt3,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _FlashText(
                    text: _formatWithCommas(meta.tokens),
                    baseStyle: mono.copyWith(
                      color: TvaColors.txt2,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Cost
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'COST',
                    style: mono.copyWith(
                      color: TvaColors.txt3,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _FlashText(
                    text: '\$${meta.cost.toStringAsFixed(2)}',
                    baseStyle: mono.copyWith(
                      color: TvaColors.txt2,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Connection status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(3.5),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: statusText == 'CONNECTED' ? 4 : 8,
                          spreadRadius: statusText == 'CONNECTED' ? 0 : 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: mono.copyWith(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: statusText != 'CONNECTED' ? FontWeight.w700 : FontWeight.normal,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Clock
              Text(
                clockText,
                style: mono.copyWith(
                  color: TvaColors.txt2,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlashText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color flashColor;

  const _FlashText({
    required this.text,
    required this.baseStyle,
    this.flashColor = TvaColors.amber, // ignore: unused_element_parameter
  });

  @override
  State<_FlashText> createState() => _FlashTextState();
}

class _FlashTextState extends State<_FlashText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _prevText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _prevText = widget.text;
  }

  @override
  void didUpdateWidget(_FlashText old) {
    super.didUpdateWidget(old);
    if (widget.text != _prevText) {
      _prevText = widget.text;
      _controller.forward(from: 0);
    }
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
        final isFlashing = _controller.isAnimating;
        return Text(
          widget.text,
          style: widget.baseStyle.copyWith(
            color: isFlashing ? widget.flashColor : widget.baseStyle.color,
          ),
        );
      },
    );
  }
}
