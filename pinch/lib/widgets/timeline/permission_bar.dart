import 'package:flutter/material.dart';

import '../../models/session_event.dart';
import '../../theme/tva_colors.dart';

class PermissionBar extends StatelessWidget {
  final SessionEvent event;
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;
  final VoidCallback? onAlways;

  const PermissionBar({
    super.key,
    required this.event,
    this.onAllow,
    this.onDeny,
    this.onAlways,
  });

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
                    fontFamily: 'IBMPlexMono',
                    fontSize: 7,
                    color: TvaColors.txt3,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  command,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    color: TvaColors.clawd,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _PermButton(
                  label: 'ALLOW', color: TvaColors.greenBr, onTap: onAllow),
              const SizedBox(width: 4),
              _PermButton(
                  label: 'DENY', color: TvaColors.rust, onTap: onDeny),
              const SizedBox(width: 4),
              _PermButton(
                label: 'ALWAYS',
                color: TvaColors.txt3,
                borderColor: TvaColors.brd,
                onTap: onAlways,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const _PermButton({
    required this.label,
    required this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  State<_PermButton> createState() => _PermButtonState();
}

class _PermButtonState extends State<_PermButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovering ? widget.color.withValues(alpha: 0.15) : null,
            border: Border.all(color: widget.borderColor ?? widget.color),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 8,
              color: widget.color,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
