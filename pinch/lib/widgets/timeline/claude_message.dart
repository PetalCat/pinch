import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clawd_state_provider.dart';
import '../../theme/tva_colors.dart';
import '../clawd/clawd_animator.dart';

class ClaudeMessage extends StatelessWidget {
  final String text;
  final bool isLatest;

  const ClaudeMessage({
    super.key,
    required this.text,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLatest)
            Consumer(
              builder: (context, ref, _) {
                final clawdState = ref.watch(clawdStateProvider);
                return SizedBox(
                  width: 100,
                  height: 44,
                  child: ClawdAnimator(
                    state: clawdState,
                    cellWidth: 2.67,
                    cellHeight: 5.87,
                  ),
                );
              },
            )
          else
            const SizedBox.shrink(),
          const Text(
            'CLAUDE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: TvaColors.amberDm,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xBFC8B99A),
            ),
          ),
        ],
      ),
    );
  }
}
