import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_session_provider.dart';
import '../providers/clawd_state_provider.dart';
import '../theme/tva_colors.dart';
import 'masthead.dart';
import 'rail.dart';
import 'sidebar.dart';
import 'ticker.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: TvaColors.bg,
      body: Column(
        children: [
          const Masthead(),
          Container(height: 1, color: TvaColors.brd),
          // Ticker
          Consumer(builder: (context, ref, _) {
            final meta = ref.watch(sessionMetaProvider);
            final clawdState = ref.watch(clawdStateProvider);
            final stateText = clawdState.name.toUpperCase();
            return Ticker(
              text:
                  'SESSION ACTIVE — MODEL: ${meta.model ?? "OPUS 4.6"} — STATUS: $stateText — PERMISSION MODE: DEFAULT',
            );
          }),
          Container(height: 1, color: TvaColors.brd),
          // Main body
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      const Rail(),
                      Container(width: 1, color: TvaColors.brd),
                      const Sidebar(),
                      Container(width: 1, color: TvaColors.brd),
                      // Content
                      Expanded(child: child),
                    ],
                  )
                : child,
          ),
        ],
      ),
    );
  }
}
