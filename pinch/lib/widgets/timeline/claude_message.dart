import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clawd_state_provider.dart';
import '../../theme/tva_colors.dart';
import '../clawd/clawd_animator.dart';
import '../clawd/clawd_state.dart';
import 'clawd_walk_controller.dart';

class ClaudeMessage extends StatefulWidget {
  final String text;
  final ClawdWalkController walkController;
  final int messageIndex;

  const ClaudeMessage({
    super.key,
    required this.text,
    required this.walkController,
    required this.messageIndex,
  });

  @override
  State<ClaudeMessage> createState() => _ClaudeMessageState();
}

class _ClaudeMessageState extends State<ClaudeMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _collapseController;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    widget.walkController.addListener(_onWalkChanged);
  }

  @override
  void didUpdateWidget(ClaudeMessage old) {
    super.didUpdateWidget(old);
    if (old.walkController != widget.walkController) {
      old.walkController.removeListener(_onWalkChanged);
      widget.walkController.addListener(_onWalkChanged);
    }
  }

  void _onWalkChanged() {
    final vis = widget.walkController.visibilityFor(widget.messageIndex);
    if (_wasActive && vis == ClawdVisibility.hidden) {
      _collapseController.forward();
    }
    if (vis == ClawdVisibility.active || vis == ClawdVisibility.arriving) {
      _wasActive = true;
      _collapseController.reset();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.walkController.removeListener(_onWalkChanged);
    _collapseController.dispose();
    super.dispose();
  }

  ClawdState _mapVisToClawdState(ClawdVisibility vis, ClawdState providerState) {
    return switch (vis) {
      ClawdVisibility.arriving => ClawdState.walkingOn,
      ClawdVisibility.departing => ClawdState.walkingOff,
      ClawdVisibility.active => providerState,
      _ => ClawdState.hidden,
    };
  }

  @override
  Widget build(BuildContext context) {
    final vis = widget.walkController.visibilityFor(widget.messageIndex);
    final showClawd = vis != ClawdVisibility.hidden;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showClawd || _wasActive)
            _buildClawdArea(vis),
          const Text(
            'CLAUDE',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              color: TvaColors.amberDm,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.text,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: Color(0xBFC8B99A),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClawdArea(ClawdVisibility vis) {
    if (vis == ClawdVisibility.hidden && _wasActive) {
      return AnimatedBuilder(
        animation: _collapseController,
        builder: (context, child) {
          return SizedBox(
            height: (1.0 - _collapseController.value) * 44,
            width: (1.0 - _collapseController.value) * 100,
          );
        },
      );
    }

    return SizedBox(
      width: 100,
      height: 44,
      child: Consumer(
        builder: (context, ref, _) {
          final providerState = ref.watch(clawdStateProvider);
          final clawdState = _mapVisToClawdState(vis, providerState);
          return ClawdAnimator(
            state: clawdState,
            cellWidth: 1.4,
            cellHeight: 3.0,
          );
        },
      ),
    );
  }
}
