import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clawd_state_provider.dart';
import '../../theme/tva_colors.dart';
import '../clawd/clawd_animator.dart';
import '../clawd/clawd_state.dart';

class ClaudeMessage extends StatefulWidget {
  final String text;
  final bool isLatest;

  const ClaudeMessage({
    super.key,
    required this.text,
    this.isLatest = false,
  });

  @override
  State<ClaudeMessage> createState() => _ClaudeMessageState();
}

class _ClaudeMessageState extends State<ClaudeMessage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clawd sprite + label
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.isLatest)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final clawdState = ref.watch(clawdStateProvider);
                        return ClawdAnimator(
                          state: clawdState,
                          cellWidth: 1.4,
                          cellHeight: 3.0,
                        );
                      },
                    ),
                  ),
                ),
              const Text(
                'CLAUDE',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  color: TvaColors.amberDm,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Response text
          Text(
            widget.text,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: Color(0xBFC8B99A), // beige with opacity
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
