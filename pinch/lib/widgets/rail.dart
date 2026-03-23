import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class Rail extends StatelessWidget {
  const Rail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: TvaColors.bgInset,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const _RailItem(label: 'H', active: true),
          const SizedBox(height: 6),
          Container(width: 20, height: 1, color: TvaColors.brd),
          const SizedBox(height: 6),
          const _RailItem(label: 'SC', active: false),
          const SizedBox(height: 6),
          const _RailItem(label: 'AP', active: false, showDot: true),
          const SizedBox(height: 6),
          const _RailItem(label: 'ML', active: false),
          const Spacer(),
          const _AddButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final String label;
  final bool active;
  final bool showDot;

  const _RailItem({
    required this.label,
    required this.active,
    this.showDot = false,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.active
        ? TvaColors.clawdDk
        : _hovering
            ? TvaColors.brd2
            : TvaColors.brd;

    final child = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.active ? TvaColors.bgRaised : TvaColors.bgPanel,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          color: widget.active ? TvaColors.clawd : TvaColors.txt3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );

    final wrapped = widget.showDot
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              const Positioned(
                top: -1,
                right: -1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TvaColors.greenBr,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 5, height: 5),
                ),
              ),
            ],
          )
        : child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {},
        child: wrapped,
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton();

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovering ? TvaColors.brd2 : TvaColors.txt3,
              style: BorderStyle.solid,
            ),
          ),
          child: const Text(
            '+',
            style: TextStyle(
              color: TvaColors.txt3,
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
