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
  String? _error;

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
      _error = null;
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
    try {
      final conn = ref.read(connectionServiceProvider);
      final events = await conn.getHistoricalSession(widget.sessionId);
      if (mounted) {
        setState(() {
          _historicalEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load session: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSendPrompt(String text) async {
    if (!_isLive && !_isResuming) {
      setState(() => _isResuming = true);

      try {
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
      } catch (e) {
        if (mounted) {
          setState(() {
            _isResuming = false;
            _error = 'Failed to resume session: $e';
          });
        }
        return;
      }
    }

    final conn = ref.read(connectionServiceProvider);
    conn.sendPrompt(widget.sessionId, text);
  }

  void _onPermission(String toolUseId, bool allowed, {bool always = false}) {
    final conn = ref.read(connectionServiceProvider);
    conn.respondToPermission(toolUseId, allowed,
        always: always, sessionId: widget.sessionId);
  }

  void _stopSession() {
    ref.read(connectionServiceProvider).stopSession(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final liveEvents = ref.watch(activeSessionEventsProvider);
    final meta = ref.watch(sessionMetaProvider);

    final allEvents = [
      ..._historicalEvents,
      if (_isLive) ...liveEvents,
    ];

    final canSend = !meta.isEnded && !_isResuming;

    return Column(
      children: [
        _buildSessionBar(meta),
        // Error banner
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0x30C03828),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFC03828)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: Color(0xFFC03828),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _error = null),
                  child: const Icon(Icons.close,
                      size: 12, color: Color(0xFFC03828)),
                ),
              ],
            ),
          ),
        // Use IndexedStack to keep both views alive when switching
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Text(
                    'Loading session...',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      color: TvaColors.txt3,
                    ),
                  ),
                )
              : IndexedStack(
                  index: _viewMode == _ViewMode.timeline ? 0 : 1,
                  children: [
                    TimelineView(
                      events: allEvents,
                      onPermission: _onPermission,
                    ),
                    PinchTerminalView(events: allEvents),
                  ],
                ),
        ),
        InputBar(
          enabled: canSend,
          onSubmit: _onSendPrompt,
        ),
        _buildStatusLine(meta),
      ],
    );
  }

  Widget _buildStatusLine(SessionMeta meta) {
    final perm = meta.permissionMode ?? 'default';
    final isDanger = perm.toLowerCase() == 'bypasspermissions' ||
        perm.toLowerCase() == 'dontask';

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDanger ? const Color(0xFF1A0A06) : TvaColors.bgInset,
        border: const Border(top: BorderSide(color: TvaColors.brd)),
      ),
      child: Row(
        children: [
          // Permission mode indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDanger
                  ? TvaColors.rust
                  : perm == 'default'
                      ? TvaColors.amber
                      : TvaColors.greenBr,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            perm,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: isDanger ? 9 : 8,
              fontWeight: isDanger ? FontWeight.w700 : FontWeight.normal,
              color: isDanger ? TvaColors.rust : TvaColors.txt3,
              letterSpacing: isDanger ? 2 : 1,
            ),
          ),
          const Spacer(),
          // Effort
          if (meta.model != null) ...[
            const Text('\u25D0 ', style: TextStyle(fontSize: 8, color: TvaColors.txt3)),
            Text(
              meta.model!.replaceAll('[1m]', ''),
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 8,
                color: TvaColors.txt3,
              ),
            ),
          ],
          const SizedBox(width: 16),
          // Cost
          if (meta.cost > 0)
            Text(
              '\$${meta.cost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 8,
                color: TvaColors.txt3,
              ),
            ),
          const SizedBox(width: 16),
          const Text(
            'Pinch',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 8,
              fontStyle: FontStyle.italic,
              color: TvaColors.txt3,
            ),
          ),
        ],
      ),
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
              color: meta.isEnded
                  ? TvaColors.txt3
                  : _isResuming
                      ? TvaColors.amber
                      : meta.isResponding
                          ? TvaColors.greenBr
                          : _isLive
                              ? TvaColors.orange
                              : TvaColors.txt3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Status badges
          if (meta.isEnded)
            _statusBadge('ENDED', TvaColors.txt3),
          if (!_isLive && !_isResuming && !meta.isEnded)
            _statusBadge('HISTORICAL', TvaColors.txt3),
          if (_isResuming)
            _statusBadge('RESUMING...', TvaColors.amber),
          if (meta.isResponding)
            _statusBadge('RESPONDING', TvaColors.greenBr),
          Text(
            sessionName,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
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
                fontFamily: 'IBMPlexMono',
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
          if (_isLive && !meta.isEnded) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _stopSession,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: TvaColors.rust),
                ),
                child: const Text(
                  'STOP',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
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

  Widget _statusBadge(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 7,
            color: color,
            letterSpacing: 1,
          ),
        ),
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
            fontFamily: 'IBMPlexMono',
            fontSize: 8,
            color: isActive ? TvaColors.amber : TvaColors.txt3,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
