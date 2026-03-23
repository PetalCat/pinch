import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'HOME',
        style: TextStyle(
          color: TvaColors.txt3,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
