import 'package:flutter/material.dart';

class ThinkingBlock extends StatefulWidget {
  final String text;
  final bool isDone;

  const ThinkingBlock({
    super.key,
    required this.text,
    this.isDone = false,
  });

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _collapsed = false;
  late AnimationController _collapseController;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = _collapseController.drive(
      Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
    );
  }

  @override
  void didUpdateWidget(ThinkingBlock old) {
    super.didUpdateWidget(old);
    // Auto-collapse when thinking is done
    if (widget.isDone && !old.isDone && !_collapsed) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_collapsed) {
          setState(() => _collapsed = true);
          _collapseController.forward();
        }
      });
    }
  }

  void _toggle() {
    setState(() => _collapsed = !_collapsed);
    if (_collapsed) {
      _collapseController.forward();
    } else {
      _collapseController.reverse();
    }
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final preview = widget.text.length > 80
        ? '${widget.text.substring(0, 80)}...'
        : widget.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF8855CC), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — always visible, acts as toggle
          GestureDetector(
            onTap: _toggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: const Color(0x08885CCC),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        size: 16, color: Color(0xFF8855CC)),
                    const SizedBox(width: 6),
                    Text(
                      _collapsed ? 'Thinking' : 'Thinking...',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 12,
                        color: Color(0xFF8855CC),
                        letterSpacing: 1,
                      ),
                    ),
                    if (_collapsed) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preview,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 11,
                            color: Color(0x888855CC),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    AnimatedRotation(
                      turns: _collapsed ? 0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right,
                          size: 12, color: Color(0xFF8855CC)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body — collapsible
          ClipRect(
            child: AnimatedBuilder(
              animation: _heightFactor,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topLeft,
                  heightFactor: _heightFactor.value,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                color: const Color(0x05885CCC),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 13,
                    color: Color(0xAA8855CC),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
