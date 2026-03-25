import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    if (isDesktop) {
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
              child: Row(
                children: [
                  const Rail(),
                  Container(width: 1, color: TvaColors.brd),
                  const Sidebar(),
                  Container(width: 1, color: TvaColors.brd),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      backgroundColor: TvaColors.bg,
      drawer: const Drawer(
        backgroundColor: TvaColors.bg2,
        width: 260,
        child: SafeArea(child: Sidebar()),
      ),
      body: Column(
        children: [
          const Masthead(),
          Container(height: 1, color: TvaColors.brd),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: TvaColors.bgInset,
        selectedItemColor: TvaColors.clawd,
        unselectedItemColor: TvaColors.txt3,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle:
            const TextStyle(fontFamily: 'IBMPlexMono', letterSpacing: 1),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'IBMPlexMono', letterSpacing: 1),
        currentIndex: _getCurrentIndex(context),
        onTap: (i) => _onTabTap(context, i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'SESSIONS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: 'DOCS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined), label: 'FILES'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'SETTINGS'),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/session')) return 0;
    if (location.startsWith('/docs')) return 1;
    if (location == '/settings') return 3;
    return 0; // home = sessions tab
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
      case 1:
        GoRouter.of(context).go('/docs');
      case 2:
        GoRouter.of(context).go('/home'); // files not a separate route yet
      case 3:
        GoRouter.of(context).go('/settings');
    }
  }
}
