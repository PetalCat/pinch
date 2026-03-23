import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

class ToolRow extends StatelessWidget {
  final SessionEvent event;

  const ToolRow({super.key, required this.event});

  Color _toolColor(String toolName) {
    switch (toolName) {
      case 'Read':
      case 'Glob':
      case 'Grep':
        return TvaColors.tealBr;
      case 'Edit':
      case 'Write':
        return TvaColors.greenBr;
      case 'Bash':
        return TvaColors.amber;
      default:
        return TvaColors.txt2;
    }
  }

  String _target() {
    final input = event.data['input'] as Map<String, dynamic>?;
    if (input == null) return '';
    if (input.containsKey('path')) return input['path'] as String;
    if (input.containsKey('file_path')) return input['file_path'] as String;
    if (input.containsKey('command')) return input['command'] as String;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final toolName = event.data['toolName'] as String? ?? '';
    final target = _target();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: TvaColors.bgInset,
        border: Border.all(color: TvaColors.brd),
      ),
      child: Row(
        children: [
          Text(
            toolName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _toolColor(toolName),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              target,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: TvaColors.txt2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            'RUNNING',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: TvaColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
