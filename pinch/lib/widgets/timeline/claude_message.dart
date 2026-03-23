import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clawd_state_provider.dart';
import '../../theme/tva_colors.dart';
import '../clawd/clawd_animator.dart';
import '../clawd/clawd_state.dart';

class ClaudeMessage extends StatefulWidget {
  final String text;
  final bool isLatest;

  const ClaudeMessage({
    super.key,
    required this.text,
    this.isLatest = false,
  });

  @override
  State<ClaudeMessage> createState() => _ClaudeMessageState();
}

class _ClaudeMessageState extends State<ClaudeMessage> {
  bool _wasActive = false;
  bool _isWalking = false;
  ClawdState _walkState = ClawdState.idle;

  @override
  void didUpdateWidget(ClaudeMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isLatest && widget.isLatest) {
      // Becoming the active message: walk on
      setState(() {
        _isWalking = true;
        _walkState = ClawdState.walkingOn;
        _wasActive = true;
      });
    } else if (oldWidget.isLatest && !widget.isLatest && _wasActive) {
      // Losing active status: walk off
      setState(() {
        _isWalking = true;
        _walkState = ClawdState.walkingOff;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isLatest) {
      _wasActive = true;
    }
  }

  void _onWalkComplete() {
    if (!mounted) return;
    setState(() {
      _isWalking = false;
      if (_walkState == ClawdState.walkingOff) {
        _wasActive = false;
      }
      _walkState = ClawdState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showClawd = widget.isLatest || _isWalking;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: showClawd
                ? SizedBox(
                    width: 100,
                    height: 44,
                    child: _isWalking
                        ? ClawdAnimator(
                            state: _walkState,
                            cellWidth: 2.67,
                            cellHeight: 5.87,
                            onWalkComplete: _onWalkComplete,
                          )
                        : Consumer(
                            builder: (context, ref, _) {
                              final clawdState =
                                  ref.watch(clawdStateProvider);
                              return ClawdAnimator(
                                state: clawdState,
                                cellWidth: 2.67,
                                cellHeight: 5.87,
                              );
                            },
                          ),
                  )
                : const SizedBox.shrink(),
          ),
          const Text(
            'CLAUDE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: TvaColors.amberDm,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xBFC8B99A),
            ),
          ),
        ],
      ),
    );
  }
}
