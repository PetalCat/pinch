import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/session.dart';
import '../providers/active_session_provider.dart';
import '../providers/clawd_state_provider.dart';
import '../providers/session_provider.dart';
import '../theme/tva_colors.dart';

// ---------------------------------------------------------------------------
// Data models (for file tree — still hardcoded)
// ---------------------------------------------------------------------------

class _FileNode {
  final String label;
  final int indent; // px
  final bool isDir;
  final bool expanded; // only relevant for dirs
  final String? countBadge;
  final bool touched;
  const _FileNode(
    this.label, {
    this.indent = 0,
    this.isDir = false,
    this.expanded = false,
    this.countBadge,
    this.touched = false,
  });
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  // ---- hardcoded data (docs & files stay) ----

  static const _docs = ['Auth design spec', 'Migration plan', 'API endpoints'];

  static const _files = [
    _FileNode('src/', indent: 0, isDir: true, expanded: true, countBadge: '4'),
    _FileNode('auth/', indent: 12, isDir: true, expanded: true),
    _FileNode('middleware.ts', indent: 24, touched: true),
    _FileNode('token.ts', indent: 24, touched: true),
    _FileNode('lib/', indent: 12, isDir: true),
    _FileNode('docs/', indent: 0, isDir: true, countBadge: '3'),
    _FileNode('tests/', indent: 0, isDir: true, countBadge: '12'),
    _FileNode('package.json', indent: 0),
  ];

  // ---- lifecycle ----

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ---- header helper ----

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: TvaColors.txt3,
        fontSize: 9,
        fontFamily: 'monospace',
        letterSpacing: 3,
      ),
    );
  }

  // ---- session item ----

  Widget _sessionItem(Session session) {
    final activeId = ref.watch(activeSessionIdProvider);
    final isActive = session.id == activeId;

    // Map session status to dot color
    Color dotColor;
    bool pulsing = false;
    switch (session.status) {
      case SessionStatus.active:
        dotColor = TvaColors.orange;
        pulsing = true;
      case SessionStatus.idle:
        dotColor = TvaColors.amber;
      case SessionStatus.ended:
        dotColor = TvaColors.brd;
    }

    // Build meta text
    String meta;
    if (isActive) {
      final sessionMeta = ref.watch(sessionMetaProvider);
      final elapsed = sessionMeta.elapsed.inMinutes;
      final clawdState = ref.watch(clawdStateProvider);
      meta = '${elapsed}m — ${clawdState.name}';
    } else {
      meta = session.status.name;
    }

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/session/${session.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x0Ac08818) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? TvaColors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusDot(dotColor, pulsing: pulsing),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.name,
                    style: TextStyle(
                      color: isActive ? TvaColors.txt : TvaColors.txt2,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 2),
              child: Text(
                meta,
                style: const TextStyle(
                  color: TvaColors.txt3,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- status dot ----

  Widget _statusDot(Color color, {bool pulsing = false}) {
    if (pulsing) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final opacity = 1.0 - (_pulse.value * 0.5); // 1.0 -> 0.5
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ---- new session button ----

  Widget _newSessionButton() {
    return GestureDetector(
      onTap: () {
        debugPrint('New session tapped — dialog not yet wired');
      },
      child: _HoverBuilder(
        builder: (hovering) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: hovering ? TvaColors.brd2 : TvaColors.brd,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '+ NEW SESSION',
              style: TextStyle(
                color: hovering ? TvaColors.txt2 : TvaColors.txt3,
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- doc item ----

  Widget _docItem(String name) {
    return _HoverBuilder(
      builder: (hovering) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            name,
            style: TextStyle(
              color: hovering ? TvaColors.amberBr : TvaColors.txt3,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  // ---- file tree item ----

  Widget _fileItem(_FileNode node) {
    final chevron = node.isDir
        ? (node.expanded ? 'v ' : '> ')
        : '  ';

    return Padding(
      padding: EdgeInsets.only(left: node.indent.toDouble(), top: 1, bottom: 1),
      child: Row(
        children: [
          Text(
            chevron,
            style: TextStyle(
              color: node.isDir && node.expanded
                  ? TvaColors.amberDm
                  : TvaColors.txt3,
              fontSize: 8,
              fontFamily: 'monospace',
            ),
          ),
          Expanded(
            child: node.touched
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: node.label,
                          style: const TextStyle(
                            color: TvaColors.txt2,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: TvaColors.amberDm,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    node.label,
                    style: const TextStyle(
                      color: TvaColors.txt3,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
          ),
          if (node.countBadge != null)
            Opacity(
              opacity: 0.5,
              child: Text(
                node.countBadge!,
                style: const TextStyle(
                  color: TvaColors.txt3,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Container(
      width: 200,
      color: TvaColors.bg2,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sessions
            _sectionHeader('SESSIONS'),
            const SizedBox(height: 8),
            sessionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: TvaColors.txt3,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Offline',
                  style: TextStyle(
                    color: TvaColors.rust,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              data: (sessions) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in sessions) _sessionItem(s),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _newSessionButton(),
            const SizedBox(height: 14),

            // Docs
            _sectionHeader('DOCS'),
            const SizedBox(height: 8),
            for (final d in _docs) _docItem(d),
            const SizedBox(height: 14),

            // Files
            _sectionHeader('FILES'),
            const SizedBox(height: 8),
            for (final f in _files) _fileItem(f),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hover helper (stateful)
// ---------------------------------------------------------------------------

class _HoverBuilder extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  const _HoverBuilder({required this.builder});

  @override
  State<_HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<_HoverBuilder> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: widget.builder(_hovering),
    );
  }
}
