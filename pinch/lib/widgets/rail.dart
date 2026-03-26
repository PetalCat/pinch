import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/project_provider.dart';
import '../theme/tva_colors.dart';

// -- Helpers ------------------------------------------------------------------

String smartShortCode(String name) {
  // Check for camelCase or multi-word
  final parts =
      name.split(RegExp(r'(?=[A-Z])|[-_ ]+')).where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  // Single word: first + last letter
  if (name.length >= 2) {
    return '${name[0]}${name[name.length - 1]}'.toUpperCase();
  }
  return name.toUpperCase();
}

const _projectColors = [
  Color(0xFFD77757), // clawd
  Color(0xFF3E8480), // teal
  Color(0xFFC08818), // amber
  Color(0xFF52902C), // green
  Color(0xFF8855CC), // purple
  Color(0xFFC44058), // rose
  Color(0xFF4488DD), // blue
  Color(0xFFE07028), // orange
  Color(0xFF9A4A30), // clawd dark
  Color(0xFF6A4C0A), // amber dark
];

Color projectColor(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _projectColors[hash.abs() % _projectColors.length];
}

// -- Rail ---------------------------------------------------------------------

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
          Tooltip(
            message: 'home',
            preferBelow: false,
            verticalOffset: 20,
            waitDuration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: TvaColors.bgRaised,
              border: Border.all(color: TvaColors.brd),
            ),
            textStyle: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: TvaColors.txt,
            ),
            child: Column(
              children: [
                _RailItem(
                  label: 'H',
                  active: true,
                  accentColor: TvaColors.clawd,
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 2),
                const Text(
                  'home',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 6,
                    color: TvaColors.clawd,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ],
            ),
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Tooltip(
                      message: p.name,
                      preferBelow: false,
                      verticalOffset: 20,
                      waitDuration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: TvaColors.bgRaised,
                        border: Border.all(color: TvaColors.brd),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        color: TvaColors.txt,
                      ),
                      child: Column(
                        children: [
                          _RailItem(
                            label: smartShortCode(p.name),
                            active: isActive,
                            showDot: isActive,
                            accentColor: projectColor(p.name),
                            onTap: () {
                              ref.read(activeProjectProvider.notifier).state = p;
                            },
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.name.length > 6 ? p.name.substring(0, 6) : p.name,
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 6,
                              color: isActive
                                  ? projectColor(p.name)
                                  : TvaColors.txt3,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ],
                      ),
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

// -- _RailItem ----------------------------------------------------------------

class _RailItem extends StatefulWidget {
  final String label;
  final bool active;
  final bool showDot;
  final Color? accentColor;
  final VoidCallback? onTap;

  const _RailItem({
    required this.label,
    required this.active,
    this.showDot = false,
    this.accentColor,
    this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? TvaColors.clawd;
    final borderColor = widget.active
        ? color
        : _hovering
            ? color.withValues(alpha: 0.5)
            : color.withValues(alpha: 0.25);
    final bgColor = widget.active
        ? color.withValues(alpha: 0.12)
        : _hovering
            ? color.withValues(alpha: 0.06)
            : TvaColors.bgPanel;
    final textColor = widget.active ? color : color.withValues(alpha: 0.7);

    final child = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'IBMPlexMono',
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

// -- _AddButton ---------------------------------------------------------------

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
              fontFamily: 'IBMPlexMono',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
