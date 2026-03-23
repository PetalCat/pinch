import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class SessionScreen extends StatelessWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'SESSION: $sessionId',
        style: const TextStyle(
          color: TvaColors.txt3,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
