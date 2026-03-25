import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_session_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';
import '../theme/tva_colors.dart';
import '../widgets/input_bar.dart';
import '../widgets/terminal/terminal_view.dart';
import '../widgets/timeline/timeline_view.dart';

enum _ViewMode { timeline, terminal }

class SessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  _ViewMode _viewMode = _ViewMode.timeline;

  @override
  void initState() {
    super.initState();
    // Set active session on init
    Future.microtask(() {
      ref.read(activeSessionIdProvider.notifier).state = widget.sessionId;
      ref.read(activeSessionEventsProvider.notifier).clearAndListenTo(widget.sessionId);
    });
  }

  @override
  void didUpdateWidget(SessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      ref.read(activeSessionIdProvider.notifier).state = widget.sessionId;
      ref.read(activeSessionEventsProvider.notifier).clearAndListenTo(widget.sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(activeSessionEventsProvider);
    final meta = ref.watch(sessionMetaProvider);

    return Column(
      children: [
        _buildSessionBar(meta),
        Expanded(
          child: _viewMode == _ViewMode.timeline
              ? TimelineView(events: events)
              : TerminalView(events: events),
        ),
        InputBar(
          enabled: !meta.isResponding,
          onSubmit: (text) {
            final conn = ref.read(connectionServiceProvider);
            conn.sendPrompt(widget.sessionId, text);
          },
        ),
      ],
    );
  }

  Widget _buildSessionBar(SessionMeta meta) {
    // Try to get session name from sessions provider
    final sessionsAsync = ref.watch(sessionsProvider);
    final sessionName = sessionsAsync.whenOrNull(
      data: (sessions) {
        try {
          return sessions
              .firstWhere((s) => s.id == widget.sessionId)
              .name;
        } catch (_) {
          return null;
        }
      },
    ) ?? widget.sessionId;

    final elapsed = '${meta.elapsed.inMinutes}m';
    final model = meta.model ?? 'opus 4.6';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: TvaColors.bg2,
        border: Border(bottom: BorderSide(color: TvaColors.brd)),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: TvaColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sessionName,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TvaColors.txt,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$elapsed — $model',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: TvaColors.txt3,
            ),
          ),
          const Spacer(),
          // Toggle group
          Row(
            children: [
              _buildToggleBtn('TIMELINE',
                  isActive: _viewMode == _ViewMode.timeline),
              _buildToggleBtn('TERMINAL',
                  isActive: _viewMode == _ViewMode.terminal),
            ],
          ),
          const SizedBox(width: 8),
          // Stop button
          GestureDetector(
            onTap: () =>
                ref.read(connectionServiceProvider).stopSession(widget.sessionId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: TvaColors.rust),
              ),
              child: const Text(
                'STOP',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: TvaColors.rust,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, {required bool isActive}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode =
              label == 'TIMELINE' ? _ViewMode.timeline : _ViewMode.terminal;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x14C08818) : Colors.transparent,
          border: Border.all(
            color: isActive ? TvaColors.amberDm : TvaColors.brd,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            color: isActive ? TvaColors.amber : TvaColors.txt3,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
