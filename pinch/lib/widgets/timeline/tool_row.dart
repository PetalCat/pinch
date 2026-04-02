import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

class ToolRow extends StatelessWidget {
  final SessionEvent event;

  const ToolRow({super.key, required this.event});

  Color _toolColor(String name) {
    return switch (name) {
      'Read' || 'Glob' || 'Grep' => TvaColors.tealBr,
      'Edit' || 'Write' => TvaColors.greenBr,
      'Bash' => TvaColors.amber,
      'Agent' => TvaColors.purple,
      _ => TvaColors.txt2,
    };
  }

  String _target() {
    final input = event.data['input'] as Map<String, dynamic>?;
    if (input == null) return '';
    return (input['file_path'] ?? input['path'] ?? input['command'] ??
        input['pattern'] ?? input['query'] ?? input['description'] ?? '')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final toolName = event.data['toolName'] as String? ?? '';
    final target = _target();
    final color = _toolColor(toolName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: TvaColors.bgInset,
        border: Border.all(color: TvaColors.brd),
      ),
      child: Row(
        children: [
          Text(
            toolName.toUpperCase(),
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              target,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 13,
                color: TvaColors.txt2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            '>',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: TvaColors.txt3,
            ),
          ),
        ],
      ),
    );
  }
}
