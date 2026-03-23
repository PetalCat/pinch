import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

const _monoStyle = TextStyle(
  fontFamily: 'IBM Plex Mono',
  fontFamilyFallback: ['monospace'],
  fontSize: 11,
  height: 1.9,
);

class TerminalView extends StatefulWidget {
  final List<SessionEvent> events;

  const TerminalView({super.key, required this.events});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  List<InlineSpan> _buildSpansForEvent(SessionEvent event) {
    switch (event.type) {
      case EventType.userMessage:
        final text = event.data['text'] as String? ?? '';
        return [
          TextSpan(text: '> ', style: _monoStyle.copyWith(color: TvaColors.txt3)),
          TextSpan(text: '$text\n', style: _monoStyle.copyWith(color: TvaColors.txt)),
        ];

      case EventType.assistantText:
        final text = event.data['text'] as String? ?? '';
        return [
          TextSpan(
            text: '$text\n',
            style: _monoStyle.copyWith(color: TvaColors.txt.withValues(alpha: 0.75)),
          ),
        ];

      case EventType.toolUse:
        return _buildToolUseSpans(event);

      case EventType.toolResult:
        return _buildToolResultSpans(event);

      case EventType.permissionRequest:
        final command = event.data['command'] as String? ?? '';
        return [
          TextSpan(
            text: '? Permission: $command\n',
            style: _monoStyle.copyWith(color: TvaColors.amber),
          ),
        ];

      default:
        return [];
    }
  }

  List<InlineSpan> _buildToolUseSpans(SessionEvent event) {
    final toolName = event.data['toolName'] as String? ?? '';
    final path = event.data['path'] as String? ?? '';

    switch (toolName) {
      case 'Read':
        return [
          TextSpan(text: '* ', style: _monoStyle.copyWith(color: TvaColors.greenBr)),
          TextSpan(text: 'Read ', style: _monoStyle.copyWith(color: TvaColors.amber)),
          TextSpan(text: '$path\n', style: _monoStyle.copyWith(color: TvaColors.clawd)),
        ];

      case 'Edit':
        final added = event.data['added'] as int? ?? 0;
        final removed = event.data['removed'] as int? ?? 0;
        return [
          TextSpan(text: '* ', style: _monoStyle.copyWith(color: TvaColors.greenBr)),
          TextSpan(text: 'Edit ', style: _monoStyle.copyWith(color: TvaColors.amber)),
          TextSpan(text: '$path ', style: _monoStyle.copyWith(color: TvaColors.clawd)),
          TextSpan(text: '+$added -$removed\n', style: _monoStyle.copyWith(color: TvaColors.txt3)),
        ];

      case 'Bash':
        final command = event.data['command'] as String? ?? '';
        return [
          TextSpan(text: '~ ', style: _monoStyle.copyWith(color: TvaColors.amber)),
          TextSpan(text: 'Bash ', style: _monoStyle.copyWith(color: TvaColors.amber)),
          TextSpan(text: '$command ', style: _monoStyle.copyWith(color: TvaColors.txt3)),
          TextSpan(text: 'RUNNING\n', style: _monoStyle.copyWith(color: TvaColors.amber)),
        ];

      default:
        return [
          TextSpan(text: '* ', style: _monoStyle.copyWith(color: TvaColors.greenBr)),
          TextSpan(text: '$toolName ', style: _monoStyle.copyWith(color: TvaColors.amber)),
          TextSpan(text: '$path\n', style: _monoStyle.copyWith(color: TvaColors.clawd)),
        ];
    }
  }

  List<InlineSpan> _buildToolResultSpans(SessionEvent event) {
    final success = event.data['success'] as bool? ?? true;
    final toolName = event.data['toolName'] as String? ?? '';
    final path = event.data['path'] as String? ?? '';
    final duration = event.data['duration'] as num? ?? 0;

    if (success) {
      return [
        TextSpan(text: '* ', style: _monoStyle.copyWith(color: TvaColors.greenBr)),
        TextSpan(text: '$toolName ', style: _monoStyle.copyWith(color: TvaColors.txt)),
        TextSpan(text: '$path ', style: _monoStyle.copyWith(color: TvaColors.txt)),
        TextSpan(text: '${duration}s\n', style: _monoStyle.copyWith(color: TvaColors.txt)),
      ];
    } else {
      final output = event.data['output'] as String? ?? 'Error';
      return [
        TextSpan(
          text: '$output\n',
          style: _monoStyle.copyWith(color: const Color(0xFFC03828)),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final event in widget.events) {
      spans.addAll(_buildSpansForEvent(event));
    }

    return Container(
      color: TvaColors.termBg,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              TextSpan(children: spans),
            ),
            AnimatedBuilder(
              animation: _cursorController,
              builder: (context, _) => Container(
                width: 6,
                height: 10,
                color: _cursorController.value < 0.5
                    ? TvaColors.amber
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
