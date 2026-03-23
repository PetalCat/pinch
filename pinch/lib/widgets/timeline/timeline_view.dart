import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import 'claude_message.dart';
import 'diff_block.dart';
import 'permission_bar.dart';
import 'result_block.dart';
import 'tool_row.dart';
import 'user_message.dart';

class TimelineView extends StatefulWidget {
  final List<SessionEvent> events;

  const TimelineView({super.key, required this.events});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();

  int get _lastClaudeIndex {
    for (int i = widget.events.length - 1; i >= 0; i--) {
      if (widget.events[i].type == EventType.assistantText) return i;
    }
    return -1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: widget.events.length,
      itemBuilder: (context, index) {
        final event = widget.events[index];
        return switch (event.type) {
          EventType.userMessage =>
            UserMessage(text: event.data['text'] as String? ?? ''),
          EventType.assistantText => ClaudeMessage(
              text: event.data['text'] as String? ?? '',
              isLatest: index == _lastClaudeIndex,
            ),
          EventType.toolUse => ToolRow(event: event),
          EventType.toolResult => _buildResult(event),
          EventType.permissionRequest => PermissionBar(event: event),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildResult(SessionEvent event) {
    final diff = event.data['diff'] as Map<String, dynamic>?;

    if (diff != null) {
      final lines = (diff['lines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
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
