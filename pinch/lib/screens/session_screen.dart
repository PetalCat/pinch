import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_event.dart';
import '../models/session_options.dart';
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
  final bool isHistorical;

  const SessionScreen({
    super.key,
    required this.sessionId,
    this.isHistorical = false,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  _ViewMode _viewMode = _ViewMode.timeline;
  bool _isLive = false;
  List<SessionEvent> _historicalEvents = [];
  bool _isLoading = true;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _isLive = !widget.isHistorical;
    if (widget.isHistorical) {
      _loadHistory();
    } else {
      _isLoading = false;
    }
    Future.microtask(() {
      ref.read(activeSessionIdProvider.notifier).state = widget.sessionId;
      if (_isLive) {
        ref
            .read(activeSessionEventsProvider.notifier)
            .clearAndListenTo(widget.sessionId);
      }
    });
  }

  @override
  void didUpdateWidget(SessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _isLive = !widget.isHistorical;
      _historicalEvents = [];
      _isLoading = widget.isHistorical;
      _isResuming = false;
      if (widget.isHistorical) {
        _loadHistory();
      }
      ref.read(activeSessionIdProvider.notifier).state = widget.sessionId;
      if (_isLive) {
        ref
            .read(activeSessionEventsProvider.notifier)
            .clearAndListenTo(widget.sessionId);
      }
    }
  }

  Future<void> _loadHistory() async {
    final conn = ref.read(connectionServiceProvider);
    final events = await conn.getHistoricalSession(widget.sessionId);
    if (mounted) {
      setState(() {
        _historicalEvents = events;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSendPrompt(String text) async {
    if (!_isLive && !_isResuming) {
      // First message on a historical session — resume it
      setState(() => _isResuming = true);

      final conn = ref.read(connectionServiceProvider);
      await conn.createSessionWithOptions(SessionOptions(
        projectDir: '',
        resumeSessionId: widget.sessionId,
      ));

      if (mounted) {
        setState(() {
          _isLive = true;
          _isResuming = false;
        });
        ref
            .read(activeSessionEventsProvider.notifier)
            .clearAndListenTo(widget.sessionId);
      }
    }

    // Send the prompt
    final conn = ref.read(connectionServiceProvider);
    conn.sendPrompt(widget.sessionId, text);
  }

  @override
  Widget build(BuildContext context) {
    final liveEvents = ref.watch(activeSessionEventsProvider);
    final meta = ref.watch(sessionMetaProvider);

    final allEvents = [
      ..._historicalEvents,
      if (_isLive) ...liveEvents,
    ];

    return Column(
      children: [
        _buildSessionBar(meta),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Text(
                    'Loading session...',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      color: TvaColors.txt3,
                    ),
                  ),
                )
              : _viewMode == _ViewMode.timeline
                  ? TimelineView(events: allEvents)
                  : TerminalView(events: allEvents),
        ),
        InputBar(
          enabled: !meta.isResponding && !_isResuming,
          onSubmit: _onSendPrompt,
        ),
      ],
    );
  }

  Widget _buildSessionBar(SessionMeta meta) {
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
        ) ??
        widget.sessionId;

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
            decoration: BoxDecoration(
              color: _isResuming
                  ? TvaColors.amber
                  : _isLive
                      ? TvaColors.orange
                      : TvaColors.txt3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          if (!_isLive && !_isResuming)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.txt3),
                ),
                child: const Text(
                  'HISTORICAL',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 7,
                    color: TvaColors.txt3,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          if (_isResuming)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.amber),
                ),
                child: const Text(
                  'RESUMING...',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 7,
                    color: TvaColors.amber,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
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
          if (_isLive)
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
          if (_isLive) ...[
            const SizedBox(width: 8),
            // Stop button
            GestureDetector(
              onTap: () => ref
                  .read(connectionServiceProvider)
                  .stopSession(widget.sessionId),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
