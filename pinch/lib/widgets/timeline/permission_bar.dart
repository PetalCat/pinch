import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

class PermissionBar extends StatelessWidget {
  final SessionEvent event;

  const PermissionBar({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final command = event.data['command'] as String? ??
        event.data['toolName'] as String? ??
        '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0AC08818),
        border: Border.all(color: const Color(0x4DC85F18)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, color: TvaColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERMISSION REQUIRED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: TvaColors.txt3,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  command,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: TvaColors.clawd,
                  ),
                ),
              ],
            ),
          ),
          const Row(
            children: [
              _PermButton(label: 'ALLOW', color: TvaColors.greenBr),
              SizedBox(width: 4),
              _PermButton(label: 'DENY', color: TvaColors.rust),
              SizedBox(width: 4),
              _PermButton(
                label: 'ALWAYS',
                color: TvaColors.txt3,
                borderColor: TvaColors.brd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? borderColor;

  const _PermButton({
    required this.label,
    required this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
