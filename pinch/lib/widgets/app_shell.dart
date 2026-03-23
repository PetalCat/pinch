import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';
import 'masthead.dart';
import 'rail.dart';
import 'sidebar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: TvaColors.bg,
      body: Column(
        children: [
          const Masthead(),
          Container(height: 1, color: TvaColors.brd),
          // Ticker placeholder
          Container(
            height: 24,
            color: TvaColors.bgInset,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: const Text(
              'SYS — SESSION ACTIVE',
              style: TextStyle(
                color: TvaColors.txt3,
                fontSize: 9,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
          Container(height: 1, color: TvaColors.brd),
          // Main body
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      const Rail(),
                      Container(width: 1, color: TvaColors.brd),
                      const Sidebar(),
                      Container(width: 1, color: TvaColors.brd),
                      // Content
                      Expanded(child: child),
                    ],
                  )
                : child,
          ),
        ],
      ),
    );
  }
}
