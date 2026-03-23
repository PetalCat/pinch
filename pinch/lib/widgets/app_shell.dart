import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

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
          // Masthead placeholder
          Container(
            height: 52,
            color: TvaColors.bgInset,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Row(
              children: [
                Text(
                  'PINCH',
                  style: TextStyle(
                    color: TvaColors.clawd,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Text(
                  'CONNECTED',
                  style: TextStyle(
                    color: TvaColors.greenBr,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
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
                      // Rail placeholder
                      Container(
                        width: 56,
                        color: TvaColors.bgInset,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            _railItem('H', true),
                            const SizedBox(height: 6),
                            Container(
                              width: 20,
                              height: 1,
                              color: TvaColors.brd,
                            ),
                            const SizedBox(height: 6),
                            _railItem('SC', false),
                            const SizedBox(height: 6),
                            _railItem('AP', false),
                          ],
                        ),
                      ),
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

  Widget _railItem(String label, bool active) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? TvaColors.bgRaised : TvaColors.bgPanel,
        border: Border.all(
          color: active ? TvaColors.clawdDk : TvaColors.brd,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? TvaColors.clawd : TvaColors.txt3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
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
