import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';
import 'claude_message.dart';
import 'clawd_walk_controller.dart';
import 'diff_block.dart';
import 'permission_bar.dart';
import 'result_block.dart';
import 'thinking_block.dart';
import 'tool_row.dart';
import 'user_message.dart';

class TimelineView extends StatefulWidget {
  final List<SessionEvent> events;
  final void Function(String toolUseId, bool allowed, {bool always})? onPermission;

  const TimelineView({
    super.key,
    required this.events,
    this.onPermission,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  final ClawdWalkController _walkController = ClawdWalkController();
  int _prevEventCount = 0;
  final Set<String> _seenEventIds = {};

  int get _lastClaudeIndex {
    for (int i = widget.events.length - 1; i >= 0; i--) {
      if (widget.events[i].type == EventType.assistantText) return i;
    }
    return -1;
  }

  bool _isThinkingDone(int index) {
    for (int i = index + 1; i < widget.events.length; i++) {
      if (widget.events[i].type != EventType.assistantThinking) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = _lastClaudeIndex;
      if (idx >= 0) {
        _walkController.setActiveMessage(idx);
      }
    });
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length > _prevEventCount) {
      _prevEventCount = widget.events.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Only trigger walk transition when latest Claude index actually changes
    if (widget.events.length != oldWidget.events.length) {
      final idx = _lastClaudeIndex;
      if (idx >= 0) {
        _walkController.setActiveMessage(idx);
      }
    }
  }

  @override
  void dispose() {
    _walkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const Center(
        child: Text(
          'Send a message to start.',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 11,
            color: TvaColors.txt3,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      itemCount: widget.events.length,
      itemBuilder: (context, index) {
        final event = widget.events[index];
        final isNew = _seenEventIds.add(event.id);
        return _FadeInWrapper(
          animate: isNew,
          child: _TimelineNode(
            event: event,
            child: _buildEventWidget(event, index),
          ),
        );
      },
    );
  }

  Widget? _buildEventWidget(SessionEvent event, int index) {
    return switch (event.type) {
      EventType.userMessage => _UserBlock(text: event.data['text'] as String? ?? ''),
      EventType.assistantText => ClaudeMessage(
          text: event.data['text'] as String? ?? '',
          walkController: _walkController,
          messageIndex: index,
        ),
      EventType.assistantThinking => ThinkingBlock(
          text: event.data['thinking'] as String? ?? '',
          isDone: _isThinkingDone(index),
        ),
      EventType.toolUse => ToolRow(event: event),
      EventType.toolResult => _buildResult(event),
      EventType.permissionRequest => PermissionBar(
          event: event,
          onAllow: () => widget.onPermission?.call(
              event.data['toolUseId'] as String? ?? '', true),
          onDeny: () => widget.onPermission?.call(
              event.data['toolUseId'] as String? ?? '', false),
          onAlways: () => widget.onPermission?.call(
              event.data['toolUseId'] as String? ?? '', true,
              always: true),
        ),
      EventType.error => _ErrorBlock(
          message: event.data['message'] as String? ?? 'Unknown error'),
      EventType.sessionEnd => _SessionEndBlock(event: event),
      EventType.turnComplete => _TurnCompleteBlock(event: event),
      _ => null,
    };
  }

  Widget _buildResult(SessionEvent event) {
    final diff = event.data['diff'] as Map<String, dynamic>?;
    if (diff != null) {
      final lines = (diff['lines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [];
      return Column(
        children: [
          DiffBlock(
            filename: diff['file'] as String? ?? '',
            added: diff['added'] as int? ?? 0,
            removed: diff['removed'] as int? ?? 0,
            lines: lines,
          ),
          ResultBlock(event: event),
        ],
      );
    }
    return ResultBlock(event: event);
  }
}

/// Timeline node wrapper — adds the vertical line + dot indicator
class _TimelineNode extends StatelessWidget {
  final SessionEvent event;
  final Widget? child;

  const _TimelineNode({required this.event, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline rail: dot + vertical line
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _buildDot(),
                  Expanded(
                    child: Container(
                      width: 1,
                      color: TvaColors.brd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(child: child!),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return switch (event.type) {
      EventType.userMessage => Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            border: Border.all(color: TvaColors.brd2),
            color: TvaColors.bgPanel,
          ),
        ),
      EventType.assistantText || EventType.assistantThinking => Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TvaColors.amber,
            boxShadow: [
              BoxShadow(
                color: TvaColors.amber.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      EventType.toolUse => Container(
          width: 5, height: 5,
          margin: const EdgeInsets.only(left: 2, top: 2),
          decoration: BoxDecoration(
            color: TvaColors.amber,
            boxShadow: [
              BoxShadow(
                color: TvaColors.amber.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      EventType.toolResult => Container(
          width: 5, height: 5,
          margin: const EdgeInsets.only(left: 2, top: 2),
          decoration: BoxDecoration(
            color: (event.data['success'] as bool? ?? true)
                ? TvaColors.greenBr
                : const Color(0xFFC03828),
            boxShadow: [
              BoxShadow(
                color: ((event.data['success'] as bool? ?? true)
                        ? TvaColors.greenBr
                        : const Color(0xFFC03828))
                    .withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      EventType.error => Container(
          width: 7, height: 7,
          margin: const EdgeInsets.only(left: 1, top: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFC03828),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC03828).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      _ => const SizedBox(width: 9, height: 9),
    };
  }
}

/// User message block
class _UserBlock extends StatelessWidget {
  final String text;
  const _UserBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOU',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              color: TvaColors.txt3,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: TvaColors.txt,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x15C03828),
        border: Border.all(color: const Color(0xFFC03828)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ERROR', style: TextStyle(
            fontFamily: 'IBMPlexMono', fontSize: 8,
            color: Color(0xFFC03828), letterSpacing: 2,
          )),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(
            fontFamily: 'IBMPlexMono', fontSize: 10,
            color: Color(0xFFC03828), height: 1.5,
          ))),
        ],
      ),
    );
  }
}

class _SessionEndBlock extends StatelessWidget {
  final SessionEvent event;
  const _SessionEndBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final cost = (event.data['cost'] as num?)?.toStringAsFixed(4) ?? '0';
    final reason = event.data['reason'] as String? ?? 'ended';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: TvaColors.brd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('SESSION $reason'.toUpperCase(), style: const TextStyle(
            fontFamily: 'IBMPlexMono', fontSize: 8,
            color: TvaColors.txt3, letterSpacing: 2,
          )),
          const SizedBox(width: 12),
          Text('\$$cost', style: const TextStyle(
            fontFamily: 'IBMPlexMono', fontSize: 8, color: TvaColors.txt3,
          )),
        ],
      ),
    );
  }
}

class _TurnCompleteBlock extends StatelessWidget {
  final SessionEvent event;
  const _TurnCompleteBlock({required this.event});

  @override
  Widget build(BuildContext context) {
    final cost = (event.data['cost'] as num?)?.toStringAsFixed(2) ?? '0';
    final duration = event.data['duration'] as num?;
    final durationStr = duration != null ? '${(duration / 1000).toStringAsFixed(1)}s' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (durationStr.isNotEmpty)
            Text(durationStr, style: const TextStyle(
              fontFamily: 'IBMPlexMono', fontSize: 8, color: TvaColors.txt3,
            )),
          if (durationStr.isNotEmpty) const SizedBox(width: 8),
          Text('\$$cost', style: const TextStyle(
            fontFamily: 'IBMPlexMono', fontSize: 8, color: TvaColors.txt3,
          )),
        ],
      ),
    );
  }
}

class _FadeInWrapper extends StatefulWidget {
  final bool animate;
  final Widget child;
  const _FadeInWrapper({required this.animate, required this.child});

  @override
  State<_FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<_FadeInWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, 6 * (1.0 - _controller.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
