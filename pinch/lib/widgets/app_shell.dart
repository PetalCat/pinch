import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/active_session_provider.dart';
import '../providers/clawd_state_provider.dart';
import '../theme/tva_colors.dart';
import 'masthead.dart';
import 'panel_corners.dart';
import 'rail.dart';
import 'sidebar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: TvaColors.bg,
        body: PanelCorners(
          child: Container(
            decoration: BoxDecoration(
              color: TvaColors.bgPanel,
              border: Border.all(color: TvaColors.brd),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(4, 4),
                  blurRadius: 16,
                  color: Color(0xCC000000),
                ),
              ],
            ),
            child: Column(
              children: [
                const Masthead(),
                Container(height: 1, color: TvaColors.brd),
                // Ticker
                Consumer(builder: (context, ref, _) {
                  final meta = ref.watch(sessionMetaProvider);
                  return _SessionInfoBar(meta: meta);
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
          ),
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

class _SessionInfoBar extends StatelessWidget {
  final SessionMeta meta;
  const _SessionInfoBar({required this.meta});

  static const _mono = TextStyle(fontFamily: 'IBMPlexMono');

  bool get _isDangerous {
    final p = meta.permissionMode?.toLowerCase() ?? '';
    return p == 'bypasspermissions' || p == 'dontask';
  }

  @override
  Widget build(BuildContext context) {
    final hasMeta = meta.model != null || meta.cwd != null;

    return Container(
      height: 28,
      color: _isDangerous ? const Color(0xFF1A0A06) : TvaColors.bgInset,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Version
          if (meta.version != null)
            _chip('v${meta.version!}', TvaColors.txt3),

          // Model
          if (meta.model != null) ...[
            const SizedBox(width: 8),
            _chip(meta.model!, TvaColors.amber),
          ],

          // CWD
          if (meta.cwd != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                meta.cwd!,
                style: _mono.copyWith(
                  fontSize: 9,
                  color: TvaColors.txt3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const Spacer(),

          // Permission mode — big and red if dangerous
          if (meta.permissionMode != null)
            _permBadge(meta.permissionMode!),

          if (!hasMeta)
            Text(
              'No active session',
              style: _mono.copyWith(fontSize: 9, color: TvaColors.txt3),
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: _mono.copyWith(
          fontSize: 8,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _permBadge(String mode) {
    final isDanger = _isDangerous;
    final color = isDanger ? TvaColors.rust : TvaColors.txt3;
    final bgColor = isDanger ? const Color(0x30C03828) : Colors.transparent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDanger ? 10 : 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isDanger ? TvaColors.rust : color.withValues(alpha: 0.3),
          width: isDanger ? 2 : 1,
        ),
      ),
      child: Text(
        mode.toUpperCase(),
        style: _mono.copyWith(
          fontSize: isDanger ? 9 : 8,
          fontWeight: isDanger ? FontWeight.w700 : FontWeight.normal,
          color: color,
          letterSpacing: isDanger ? 2 : 0.5,
        ),
      ),
    );
  }
}
