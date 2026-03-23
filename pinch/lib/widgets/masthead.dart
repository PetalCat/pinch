import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/clawd_state_provider.dart';
import '../theme/tva_colors.dart';
import 'clawd/clawd_animator.dart';

class Masthead extends ConsumerWidget {
  const Masthead({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clawdState = ref.watch(clawdStateProvider);
    const mono = TextStyle(fontFamily: 'IBMPlexMono');

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
                'OPS',
                style: mono.copyWith(
                  color: TvaColors.txt3,
                  fontSize: 8,
                  letterSpacing: 2,
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
                  Text(
                    '24,819',
                    key: const Key('masthead_token_count'),
                    style: mono.copyWith(
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
                  Text(
                    r'$0.12',
                    style: mono.copyWith(
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
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: TvaColors.greenBr,
                      borderRadius: BorderRadius.circular(2.5),
                      boxShadow: [
                        BoxShadow(
                          color: TvaColors.greenBr.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CONNECTED',
                    style: mono.copyWith(
                      color: TvaColors.greenBr,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Clock
              Text(
                '00:00:00',
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
