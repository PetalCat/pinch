import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

/// Collapsible nested panel for Agent / subagent tool calls.
///
/// Shows the task description inline, and the result in an expandable body.
class SubagentPanel extends StatefulWidget {
  final SessionEvent toolUse;
  final SessionEvent? result;

  const SubagentPanel({super.key, required this.toolUse, this.result});

  @override
  State<SubagentPanel> createState() => _SubagentPanelState();
}

class _SubagentPanelState extends State<SubagentPanel> {
  bool _expanded = false;

  @override
  void didUpdateWidget(SubagentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when result arrives
    if (oldWidget.result == null && widget.result != null) {
      setState(() => _expanded = true);
    }
  }

  String get _description {
    final input = widget.toolUse.data['input'] as Map<String, dynamic>?;
    return (input?['description'] ?? input?['prompt'] ?? '').toString();
  }

  String? get _agentType {
    final input = widget.toolUse.data['input'] as Map<String, dynamic>?;
    return input?['subagent_type'] as String?;
  }

  String get _resultText =>
      widget.result?.data['output'] as String? ?? '';

  bool get _resultSuccess =>
      widget.result?.data['success'] as bool? ?? true;

  bool get _hasResult => widget.result != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A12),
        border: Border.all(color: TvaColors.purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          GestureDetector(
            onTap: _hasResult ? () => setState(() => _expanded = !_expanded) : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TvaColors.purple.withValues(alpha: 0.08),
                border: Border(
                  bottom: _expanded
                      ? BorderSide(color: TvaColors.purple.withValues(alpha: 0.2))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  // Purple square marker
                  Container(
                    width: 7,
                    height: 7,
                    color: TvaColors.purple,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SUBAGENT',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      color: TvaColors.purple,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_agentType != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '· ${_agentType!.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 9,
                        color: TvaColors.txt3,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Status indicator
                  if (!_hasResult)
                    _PulsingDot()
                  else
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: TvaColors.purple.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          ),

          // Task description
          if (_description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Text(
                _description,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: TvaColors.txt2,
                  height: 1.4,
                ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),

          // Result body (collapsible)
          if (_expanded && _hasResult)
            _ResultBody(
              output: _resultText,
              success: _resultSuccess,
            ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final String output;
  final bool success;
  const _ResultBody({required this.output, required this.success});

  static const int _maxChars = 1200;

  @override
  Widget build(BuildContext context) {
    final trimmed = output.length > _maxChars
        ? '${output.substring(0, _maxChars)}\n… (truncated)'
        : output;
    final color = success ? TvaColors.greenBr : const Color(0xFFC03828);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF080706),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: SelectableText(
        trimmed.isEmpty ? '(no output)' : trimmed,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          color: trimmed.isEmpty ? TvaColors.txt3 : TvaColors.txt2,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TvaColors.purple.withValues(alpha: 0.3 + 0.7 * _ctrl.value),
        ),
      ),
    );
  }
}
