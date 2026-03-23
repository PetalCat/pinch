import 'package:flutter/material.dart';

import '../../theme/tva_colors.dart';
import 'clawd_sprite.dart';
import 'clawd_state.dart';

class ClawdAnimator extends StatefulWidget {
  final ClawdState state;
  final double cellWidth;
  final double cellHeight;

  const ClawdAnimator({
    super.key,
    this.state = ClawdState.idle,
    this.cellWidth = 6.0,
    this.cellHeight = 13.0,
  });

  @override
  State<ClawdAnimator> createState() => _ClawdAnimatorState();
}

class _ClawdAnimatorState extends State<ClawdAnimator>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _blinkController;
  late AnimationController _shakeController;

  // For success hop
  late AnimationController _hopController;

  // For thinking eye color cycle
  late AnimationController _colorCycleController;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _colorCycleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _applyState();
  }

  @override
  void didUpdateWidget(ClawdAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyState();
    }
  }

  void _applyState() {
    // Reset all optional controllers
    _shakeController.stop();
    _shakeController.reset();
    _hopController.stop();
    _hopController.reset();
    _colorCycleController.stop();
    _colorCycleController.reset();

    switch (widget.state) {
      case ClawdState.idle:
      case ClawdState.reading:
      case ClawdState.editing:
        _bobController.duration = const Duration(seconds: 2);
        _bobController.repeat();

      case ClawdState.thinking:
        _bobController.duration = const Duration(seconds: 2);
        _bobController.repeat();
        _colorCycleController.repeat();

      case ClawdState.bash:
      case ClawdState.typing:
        _bobController.duration = const Duration(milliseconds: 300);
        _bobController.repeat();

      case ClawdState.error:
        _bobController.stop();
        _shakeController.repeat();

      case ClawdState.success:
        _bobController.stop();
        _hopController.forward();

      case ClawdState.walkingOff:
      case ClawdState.walkingOn:
        _bobController.duration = const Duration(milliseconds: 300);
        _bobController.repeat();

      case ClawdState.hidden:
        _bobController.stop();
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _blinkController.dispose();
    _shakeController.dispose();
    _hopController.dispose();
    _colorCycleController.dispose();
    super.dispose();
  }

  Color _glowColor() {
    switch (widget.state) {
      case ClawdState.reading:
        return TvaColors.tealBr;
      case ClawdState.editing:
      case ClawdState.success:
        return TvaColors.greenBr;
      case ClawdState.bash:
      case ClawdState.typing:
        return TvaColors.amber;
      case ClawdState.error:
        return TvaColors.rust;
      case ClawdState.thinking:
        return TvaColors.purple;
      default:
        return TvaColors.clawd;
    }
  }

  Color _eyeColor() {
    if (widget.state == ClawdState.error) return TvaColors.rust;

    if (widget.state == ClawdState.thinking) {
      // Snap through purple -> teal -> amber
      final v = _colorCycleController.value;
      if (v < 1 / 3) return TvaColors.purple;
      if (v < 2 / 3) return TvaColors.tealBr;
      return TvaColors.amber;
    }

    return TvaColors.bgInset;
  }

  bool _showEyes() {
    // Blink: eyes hide at 90-94% of 5s cycle
    final bv = _blinkController.value;
    if (bv >= 0.90 && bv < 0.94) return false;
    return true;
  }

  double _translateX() {
    if (widget.state == ClawdState.error) {
      // Shake: snap between -1 and +1
      final v = _shakeController.value;
      if (v < 0.25) return -1.0;
      if (v < 0.5) return 1.0;
      if (v < 0.75) return -1.0;
      return 1.0;
    }
    return 0.0;
  }

  double _translateY() {
    if (widget.state == ClawdState.success) {
      // Hop: snap to -3px in first half, back to 0 in second half
      final v = _hopController.value;
      return v < 0.5 ? -3.0 : 0.0;
    }

    if (widget.state == ClawdState.error ||
        widget.state == ClawdState.hidden) {
      return 0.0;
    }

    // Bob: snap between 0 and -1
    final v = _bobController.value;
    return v < 0.5 ? 0.0 : -1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == ClawdState.hidden) {
      return SizedBox(
        width: widget.cellWidth * 18,
        height: widget.cellHeight * 5,
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        _bobController,
        _blinkController,
        _shakeController,
        _hopController,
        _colorCycleController,
      ]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(_translateX(), _translateY()),
          child: ClawdSprite(
            cellWidth: widget.cellWidth,
            cellHeight: widget.cellHeight,
            glowColor: _glowColor(),
            eyeColor: _eyeColor(),
            showEyes: _showEyes(),
          ),
        );
      },
    );
  }
}
