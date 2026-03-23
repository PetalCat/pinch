import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';
import 'masthead.dart';
import 'rail.dart';

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
                      // Sidebar placeholder
                      Container(
                        width: 200,
                        color: TvaColors.bg2,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SESSIONS',
                              style: TextStyle(
                                color: TvaColors.txt3,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _sidebarItem('Fix auth middleware', true),
                            _sidebarItem('Add dark mode', false),
                          ],
                        ),
                      ),
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

  Widget _sidebarItem(String name, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0x0Ac08818) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: active ? TvaColors.amber : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: active ? TvaColors.txt : TvaColors.txt2,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
