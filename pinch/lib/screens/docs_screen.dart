import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'DOCS',
        style: TextStyle(
          color: TvaColors.txt3,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
