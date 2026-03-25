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
        ConnectionStatus.connecting => (TvaColors.amber, 'CONNECTING'),
        ConnectionStatus.error => (TvaColors.rust, 'ERROR'),
        ConnectionStatus.disconnected => (TvaColors.txt3, 'OFFLINE'),
      },
      loading: () => (TvaColors.amber, 'CONNECTING'),
      error: (_, __) => (TvaColors.rust, 'ERROR'),
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
                    _formatWithCommas(meta.tokens),
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
                    '\$${meta.cost.toStringAsFixed(2)}',
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
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2.5),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 4,
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
