import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

class ResultBlock extends StatelessWidget {
  final SessionEvent event;

  const ResultBlock({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final success = event.data['success'] as bool? ?? true;
    final output = event.data['output'] as String? ?? '';
    final duration = event.data['duration'] as num?;
    final color = success ? TvaColors.greenBr : const Color(0xFFC03828);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (output.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF080704),
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Text(
              output,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: color,
              ),
            ),
          ),
        if (duration != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${duration.toStringAsFixed(1)}s',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: TvaColors.txt3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
