import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'SETTINGS',
        style: TextStyle(
          color: TvaColors.txt3,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
