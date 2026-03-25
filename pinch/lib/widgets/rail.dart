import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/project_provider.dart';
import '../theme/tva_colors.dart';

class Rail extends ConsumerWidget {
  const Rail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final activeProject = ref.watch(activeProjectProvider);

    return Container(
      width: 56,
      color: TvaColors.bgInset,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _RailItem(
            label: 'H',
            active: true,
            onTap: () => context.go('/home'),
          ),
          const SizedBox(height: 6),
          Container(width: 20, height: 1, color: TvaColors.brd),
          const SizedBox(height: 6),
          // Scrollable project list
          Expanded(
            child: projectsAsync.when(
              data: (projects) => ListView(
                padding: EdgeInsets.zero,
                children: projects.map((p) {
                  final isActive = activeProject?.id == p.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _RailItem(
                      label: p.shortCode ?? p.name.substring(0, 2).toUpperCase(),
                      active: isActive,
                      showDot: isActive,
                      onTap: () {
                        ref.read(activeProjectProvider.notifier).state = p;
                      },
                    ),
                  );
                }).toList(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          _AddButton(onTap: () => context.go('/projects')),
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
  final VoidCallback? onTap;

  const _RailItem({
    required this.label,
    required this.active,
    this.showDot = false,
    this.onTap,
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
        onTap: widget.onTap,
        child: wrapped,
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _AddButton({this.onTap});

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
        onTap: widget.onTap,
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
