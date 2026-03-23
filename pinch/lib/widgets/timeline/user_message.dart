import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';

class UserMessage extends StatelessWidget {
  final String text;

  const UserMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOU',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: TvaColors.txt3,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: TvaColors.txt,
            ),
          ),
        ],
      ),
    );
  }
}
