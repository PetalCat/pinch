import 'package:flutter/material.dart';

import '../theme/tva_colors.dart';

class InputBar extends StatefulWidget {
  final ValueChanged<String>? onSubmit;
  final bool enabled;

  const InputBar({super.key, this.onSubmit, this.enabled = true});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  late final AnimationController _chevronController;

  static const _monoStyle = TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontFamilyFallback: ['monospace'],
    fontSize: 12,
    color: TvaColors.txt,
  );

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.enabled) {
      _chevronController.repeat();
    }
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _chevronController.repeat();
    } else if (!widget.enabled && oldWidget.enabled) {
      _chevronController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _chevronController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: TvaColors.bg2,
        border: Border(top: BorderSide(color: TvaColors.brd)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TvaColors.bgInset,
          border: Border.all(color: _hasFocus ? TvaColors.amberDm : TvaColors.brd),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _chevronController,
              builder: (context, _) {
                final v = _chevronController.value;
                // Mockup: 0-30% → 1.0, 30-60% → 0.3, 60-90% → 1.0, 90-100% → 0.3
                final opacity = (v < 0.3 || (v >= 0.6 && v < 0.9)) ? 1.0 : 0.3;
                return Opacity(
                  opacity: widget.enabled ? opacity : 0.5,
                  child: const Text(
                    '>',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontFamilyFallback: ['monospace'],
                      fontSize: 12,
                      color: TvaColors.amberDm,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                style: _monoStyle,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter prompt...',
                  hintStyle: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontFamilyFallback: ['monospace'],
                    fontSize: 12,
                    color: TvaColors.txt3,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.enabled ? () => _submit() : null,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Opacity(
                  opacity: widget.enabled ? 1.0 : 0.4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: TvaColors.orange,
                      border:
                          Border.all(color: TvaColors.orangeBr, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(2, 2),
                          color: TvaColors.orangeDm,
                        ),
                      ],
                    ),
                    child: const Text(
                      'SEND',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontFamilyFallback: ['monospace'],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: TvaColors.parch,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
