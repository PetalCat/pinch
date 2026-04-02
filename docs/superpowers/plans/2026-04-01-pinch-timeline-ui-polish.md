# Pinch Timeline UI Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Pinch Flutter app's timeline view match the canonical HTML mockup at `/.superpowers/brainstorm/13710-1774232768/tva-clawd-live.html`

**Architecture:** The changes are organized in three phases: (1) timeline core animations — Clawd walk transitions, fade-in, typing indicator, panel decoration; (2) input bar, terminal, thinking polish; (3) additional visual effects (CRT overlay, ticker bar, token flash, space collapse, sidebar sync). Each task modifies 1-3 files and can be verified visually via hot reload.

**Tech Stack:** Flutter/Dart, Riverpod, custom animations via AnimationController

**Testing:** This is visual animation work. No unit tests — verify each task by running `cd ~/Developer/ClaudeCode/pinch && flutter run -d macos` and visually confirming against the mockup. Run `pnpm check` (from project root) after each task to ensure no type errors.

**Key reference:** The mockup HTML contains all target CSS animations/keyframes. Line references to the mockup are included where relevant.

---

## Phase 1: Timeline Core

### Task 1: Clawd Walk Transition Controller

The biggest gap. Currently `ClaudeMessage.isLatest` just shows/hides Clawd. The mockup has a full walk-off → space-collapse → walk-on state machine coordinated across messages.

**Files:**
- Create: `pinch/lib/widgets/timeline/clawd_walk_controller.dart`
- Modify: `pinch/lib/widgets/timeline/timeline_view.dart`
- Modify: `pinch/lib/widgets/timeline/claude_message.dart`

- [ ] **Step 1: Create ClawdWalkController**

This ChangeNotifier manages which Claude message index has the active (visible, animated) Clawd, and coordinates walk-off/walk-on transitions between messages.

```dart
// pinch/lib/widgets/timeline/clawd_walk_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

enum ClawdVisibility {
  hidden,      // no clawd, no space
  arriving,    // walking on (800ms)
  active,      // settled, showing current state
  departing,   // walking off (800ms)
  collapsed,   // space animating to zero
}

class ClawdWalkController extends ChangeNotifier {
  static const _walkDuration = Duration(milliseconds: 800);

  int? _activeIndex;
  int? _departingIndex;
  bool _isTransitioning = false;
  Timer? _walkTimer;

  int? get activeIndex => _activeIndex;
  int? get departingIndex => _departingIndex;

  ClawdVisibility visibilityFor(int index) {
    if (index == _departingIndex) return ClawdVisibility.departing;
    if (index == _activeIndex) {
      return _isTransitioning ? ClawdVisibility.arriving : ClawdVisibility.active;
    }
    // Any previously-active index that's neither active nor departing is collapsed
    return ClawdVisibility.hidden;
  }

  void setActiveMessage(int newIndex) {
    if (newIndex == _activeIndex && !_isTransitioning) return;

    _walkTimer?.cancel();

    if (_activeIndex != null && _activeIndex != newIndex) {
      // Walk off old, then walk on new
      _departingIndex = _activeIndex;
      _activeIndex = newIndex;
      _isTransitioning = true;
      notifyListeners();

      // After walk-off completes, start walk-on
      _walkTimer = Timer(_walkDuration, () {
        _departingIndex = null;
        notifyListeners();

        // After walk-on completes, settle
        _walkTimer = Timer(_walkDuration, () {
          _isTransitioning = false;
          notifyListeners();
        });
      });
    } else {
      // First clawd or same index — just walk on
      _activeIndex = newIndex;
      _isTransitioning = true;
      notifyListeners();

      _walkTimer = Timer(_walkDuration, () {
        _isTransitioning = false;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: Integrate controller into TimelineView**

Add the controller as state in `_TimelineViewState` and pass it to child widgets. When a new `assistantText` event appears, call `setActiveMessage`.

In `pinch/lib/widgets/timeline/timeline_view.dart`:

Add to `_TimelineViewState`:
```dart
final ClawdWalkController _walkController = ClawdWalkController();
```

In `dispose()`, add `_walkController.dispose();`

In `didUpdateWidget`, after the auto-scroll logic, add:
```dart
// Find latest assistant text index and trigger walk transition
final lastClaudeIdx = _lastClaudeIndex;
if (lastClaudeIdx >= 0) {
  _walkController.setActiveMessage(lastClaudeIdx);
}
```

Also do the same in `initState` (for initial load).

Pass `_walkController` to `ClaudeMessage`:
```dart
EventType.assistantText => ClaudeMessage(
    text: event.data['text'] as String? ?? '',
    walkController: _walkController,
    messageIndex: index,
  ),
```

- [ ] **Step 3: Update ClaudeMessage to use walk controller**

Replace the `isLatest` parameter with `walkController` + `messageIndex`. The widget listens to the controller and renders the appropriate walk state.

```dart
// pinch/lib/widgets/timeline/claude_message.dart
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
    // If was active/departing and now hidden, start collapse
    if (_wasActive && vis == ClawdVisibility.hidden) {
      _collapseController.forward();
    }
    if (vis == ClawdVisibility.active || vis == ClawdVisibility.arriving) {
      _wasActive = true;
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
          // Clawd area — collapsible
          if (showClawd || _wasActive)
            _buildClawdArea(vis),
          // Label
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
          // Response text
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
      // Collapsing: animate height to zero
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
```

- [ ] **Step 4: Verify walk transitions**

Run: `cd ~/Developer/ClaudeCode/pinch && flutter run -d macos`

Send a message and watch: first Claude response should have Clawd walk on from left. Send another message — old Clawd should walk off left, space should collapse, new Clawd should walk on. Historical messages should have no Clawd visible.

- [ ] **Step 5: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/timeline/clawd_walk_controller.dart pinch/lib/widgets/timeline/claude_message.dart pinch/lib/widgets/timeline/timeline_view.dart
git commit -m "feat(pinch): add Clawd walk-on/walk-off transitions between messages"
```

---

### Task 2: Timeline Entry Fade-In Animation

New timeline items should fade in with translateY(6px) → 0 over 300ms. Only applies to NEW items, not items already visible on load.

**Files:**
- Modify: `pinch/lib/widgets/timeline/timeline_view.dart`

- [ ] **Step 1: Add fade-in wrapper to _TimelineNode**

Track which event indices have already been seen. Wrap new items in a `_FadeInWrapper`.

Add to `_TimelineViewState`:
```dart
final Set<String> _seenEventIds = {};
```

In `itemBuilder`, check if the event was already seen:
```dart
final isNew = _seenEventIds.add(event.id);
return _FadeInWrapper(
  animate: isNew,
  child: _TimelineNode(
    event: event,
    child: _buildEventWidget(event, index),
  ),
);
```

- [ ] **Step 2: Create _FadeInWrapper widget**

Add this private widget to `timeline_view.dart`:

```dart
class _FadeInWrapper extends StatefulWidget {
  final bool animate;
  final Widget child;
  const _FadeInWrapper({required this.animate, required this.child});

  @override
  State<_FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<_FadeInWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, 6 * (1.0 - _controller.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
```

- [ ] **Step 3: Verify**

Run app, send a message. New timeline entries should fade in from slightly below. Existing entries on load should appear instantly.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/timeline/timeline_view.dart
git commit -m "feat(pinch): add fade-in animation for new timeline entries"
```

---

### Task 3: Typing Indicator (3 Animated Dots)

When Clawd is in `typing` state, show 3 pulsing dots next to the sprite. Mockup: `.type-indicator .ti-dot` with staggered `dot-pulse` animation.

**Files:**
- Create: `pinch/lib/widgets/clawd/typing_indicator.dart`
- Modify: `pinch/lib/widgets/clawd/clawd_animator.dart`

- [ ] **Step 1: Create TypingIndicator widget**

```dart
// pinch/lib/widgets/clawd/typing_indicator.dart
import 'package:flutter/material.dart';
import '../../theme/tva_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0.0),
            const SizedBox(width: 3),
            _dot(0.2),
            const SizedBox(width: 3),
            _dot(0.4),
          ],
        );
      },
    );
  }

  Widget _dot(double delay) {
    // Each dot pulses: 0.3 opacity baseline, 1.0 at peak
    // Stagger by delay fraction of the cycle
    final adjusted = (_controller.value + delay) % 1.0;
    final opacity = adjusted < 0.5
        ? 0.3 + 0.7 * (adjusted / 0.5)   // ramp up
        : 0.3 + 0.7 * (1.0 - (adjusted - 0.5) / 0.5); // ramp down
    // Snap to steps for pixel feel
    final snapped = (opacity * 4).round() / 4.0;

    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: TvaColors.amber.withValues(alpha: snapped),
      ),
    );
  }
}
```

- [ ] **Step 2: Add TypingIndicator to ClawdAnimator**

In `clawd_animator.dart`, modify `_buildProp()` to return TypingIndicator for the `typing` state:

```dart
Widget? _buildProp() {
  switch (widget.state) {
    case ClawdState.reading:
      return const ReadProp();
    case ClawdState.editing:
      return const EditProp();
    case ClawdState.bash:
      return const BashProp();
    case ClawdState.typing:
      return const TypingIndicator();
    default:
      return null;
  }
}
```

Add import: `import 'typing_indicator.dart';`

- [ ] **Step 3: Verify**

Run app. When Claude is generating text (before first text arrives), the typing state should show 3 staggered pulsing amber dots next to Clawd.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/clawd/typing_indicator.dart pinch/lib/widgets/clawd/clawd_animator.dart
git commit -m "feat(pinch): add typing indicator dots next to Clawd"
```

---

### Task 4: Panel Corner Brackets

Decorative corner brackets on the main app panel. Mockup: `.cn` elements — 8x8px L-shaped brackets at each corner with `brd-ac` color (gold).

**Files:**
- Create: `pinch/lib/widgets/panel_corners.dart`
- Modify: `pinch/lib/widgets/app_shell.dart`

- [ ] **Step 1: Create PanelCorners widget**

A Stack overlay that draws 4 corner brackets on top of its child.

```dart
// pinch/lib/widgets/panel_corners.dart
import 'package:flutter/material.dart';
import '../theme/tva_colors.dart';

class PanelCorners extends StatelessWidget {
  final Widget child;
  const PanelCorners({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Top-left
        const Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
        // Top-right
        const Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
        // Bottom-left
        const Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
        // Bottom-right
        const Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TvaColors.brdAc
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (top && left) {
      // Top-left: down then right
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      // Top-right: left then down
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      // Bottom-left: up then right
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Bottom-right: left then up
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 2: Wrap desktop Scaffold body with PanelCorners**

In `app_shell.dart`, wrap the desktop layout's main body Column with PanelCorners. Add border around it to match mockup `.panel` style.

In the desktop branch of `build()`:
```dart
return Scaffold(
  backgroundColor: TvaColors.bg,
  body: PanelCorners(
    child: Container(
      decoration: BoxDecoration(
        color: TvaColors.bgPanel,
        border: Border.all(color: TvaColors.brd),
        boxShadow: const [
          BoxShadow(
            offset: Offset(4, 4),
            blurRadius: 16,
            color: Color(0xCC000000),
          ),
        ],
      ),
      child: Column(
        children: [
          const Masthead(),
          // ... rest unchanged
        ],
      ),
    ),
  ),
);
```

Add import: `import 'panel_corners.dart';`

- [ ] **Step 3: Verify**

Run app. Should see gold L-shaped brackets at each corner of the main panel.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/panel_corners.dart pinch/lib/widgets/app_shell.dart
git commit -m "feat(pinch): add decorative panel corner brackets"
```

---

### Task 5: Gold Scan Line

An animated line that sweeps from top to bottom of the panel. Mockup: `@keyframes scan { 0%{top:0} 100%{top:100%} }` over 13s.

**Files:**
- Modify: `pinch/lib/widgets/panel_corners.dart`

- [ ] **Step 1: Add ScanLine to PanelCorners**

Convert PanelCorners to a StatefulWidget and add a scan line animation.

```dart
class PanelCorners extends StatefulWidget {
  final Widget child;
  const PanelCorners({super.key, required this.child});

  @override
  State<PanelCorners> createState() => _PanelCornersState();
}

class _PanelCornersState extends State<PanelCorners>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Scan line
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ScanLinePainter(_scanController.value),
                );
              },
            ),
          ),
        ),
        // Corners
        const Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
        const Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
        const Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
        const Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
      ],
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0x40D4A428), // amber-br at 25% opacity
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 1));
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
```

- [ ] **Step 2: Verify**

Run app. A subtle gold line should sweep slowly from top to bottom of the main panel on a 13s loop.

- [ ] **Step 3: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/panel_corners.dart
git commit -m "feat(pinch): add gold scan line animation to panel"
```

---

## Phase 2: Input, Terminal, Thinking

### Task 6: Input Bar Polish

Match mockup chevron blink timing (1.2s, step-end pattern) and add focus-state amber border.

**Files:**
- Modify: `pinch/lib/widgets/input_bar.dart`

- [ ] **Step 1: Fix chevron blink timing**

Change the chevron animation to match the mockup's `@keyframes chevron-blink { 0%,60%{opacity:1} 30%,90%{opacity:0.3} }` with 1.2s duration.

In `_InputBarState.initState`:
```dart
_chevronController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1200),
);
```

In the `AnimatedBuilder` for the chevron, change the opacity logic:
```dart
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
```

- [ ] **Step 2: Add focus-state border change**

Add a `FocusNode` and listen for focus changes to toggle the border color.

Add to `_InputBarState`:
```dart
final _focusNode = FocusNode();
bool _hasFocus = false;
```

In `initState`, add:
```dart
_focusNode.addListener(() {
  setState(() => _hasFocus = _focusNode.hasFocus);
});
```

In `dispose`, add `_focusNode.dispose();`

On the inner Container, change the border:
```dart
border: Border.all(
  color: _hasFocus ? TvaColors.amberDm : TvaColors.brd,
),
```

Pass `_focusNode` to the TextField:
```dart
TextField(
  controller: _controller,
  focusNode: _focusNode,
  enabled: widget.enabled,
  // ...
```

- [ ] **Step 3: Verify**

Run app. Chevron should blink with the step-end pattern. Clicking the input should change border to amber-dm.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/input_bar.dart
git commit -m "feat(pinch): polish input bar chevron blink and focus border"
```

---

### Task 7: Thinking Block Polish

The thinking block works but needs visual refinements: match the mockup's expand/collapse behavior more closely, ensure the purple styling matches.

**Files:**
- Modify: `pinch/lib/widgets/timeline/thinking_block.dart`

- [ ] **Step 1: Improve collapse animation**

The current implementation is close. Two refinements:
1. When collapsed, the preview text should appear inline with "Thinking" (not on a separate line)
2. The chevron should point right when collapsed and rotate to down when expanded (currently reversed)

Fix the `AnimatedRotation` — collapsed should be 0 turns (right), expanded should be 0.25 turns (down):
```dart
AnimatedRotation(
  turns: _collapsed ? 0 : 0.25,
  duration: const Duration(milliseconds: 200),
  child: const Icon(Icons.chevron_right,
      size: 12, color: Color(0xFF8855CC)),
),
```

This is actually correct already. The only thing to verify is the visual behavior matches. No code change needed here.

- [ ] **Step 2: Add thinking dots animation when not done**

When thinking is in progress (isDone=false), show animated dots after "Thinking":

Replace the header text:
```dart
Text(
  widget.isDone
      ? (_collapsed ? 'Thinking' : 'Thinking')
      : 'Thinking...',
  // ...
),
```

This is also correct already. The thinking block is close to the mockup. Skip to commit.

- [ ] **Step 3: Verify and commit**

Run app and verify thinking blocks match the mockup. If they already do, commit any changes or skip.

```bash
cd ~/Developer/ClaudeCode && git add -u && git diff --cached --stat
# Only commit if there are changes
```

---

### Task 8: Terminal View Styling

The terminal view should match the mockup's styling more closely. Key differences: background color, font size, line height, prompt styling.

**Files:**
- Modify: `pinch/lib/widgets/terminal/terminal_view.dart`

- [ ] **Step 1: Read current terminal_view.dart**

Read the file first to understand the current implementation before making changes.

- [ ] **Step 2: Match mockup terminal styles**

The mockup's terminal styles:
- Background: `#060503` (TvaColors.termBg)
- Font: mono, 0.62rem (~10px), line-height 1.9
- Padding: 14px 18px
- Colors: `.t-dim` = txt3, `.t-txt` = txt, `.t-cmd` = amber, `.t-ok` = green-br, `.t-file` = clawd, `.t-err` = #c03828

Adjust the terminal view's text styles and container to match these values. Specific changes depend on the current state of terminal_view.dart.

- [ ] **Step 3: Verify and commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/terminal/terminal_view.dart
git commit -m "feat(pinch): polish terminal view styling to match mockup"
```

---

## Phase 3: Additional Visual Effects

### Task 9: CRT Scanline Overlay

The mockup has a `body::after` pseudo-element creating a CRT TV scanline effect across the entire app.

**Files:**
- Modify: `pinch/lib/widgets/app_shell.dart`

- [ ] **Step 1: Add CRT overlay**

Add a `Positioned.fill` overlay in the desktop layout that draws repeating horizontal lines.

After the `PanelCorners` widget in the Stack (or at the very top of the Scaffold body), add:

```dart
// CRT scanline overlay
Positioned.fill(
  child: IgnorePointer(
    child: CustomPaint(
      painter: _CrtScanlinePainter(),
    ),
  ),
),
```

The painter:
```dart
class _CrtScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0D000000); // ~5% black
    for (double y = 2; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 2: Verify and commit**

Should see very subtle horizontal lines across the app, like an old CRT monitor.

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/app_shell.dart
git commit -m "feat(pinch): add CRT scanline overlay effect"
```

---

### Task 10: Ticker Bar

Scrolling system info strip below the masthead. Mockup: `.tkr` with `.tkr-l` (label) and `.tkr-t` (scrolling text).

**Files:**
- Create: `pinch/lib/widgets/ticker_bar.dart`
- Modify: `pinch/lib/widgets/app_shell.dart`

- [ ] **Step 1: Create TickerBar widget**

```dart
// pinch/lib/widgets/ticker_bar.dart
import 'package:flutter/material.dart';
import '../theme/tva_colors.dart';

class TickerBar extends StatefulWidget {
  final String label;
  final String text;
  const TickerBar({super.key, this.label = 'SYS', required this.text});

  @override
  State<TickerBar> createState() => _TickerBarState();
}

class _TickerBarState extends State<TickerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: TvaColors.bgInset,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              letterSpacing: 2,
              color: TvaColors.amberDm,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return FractionalTranslation(
                  translation: Offset(
                    0.6 - _scrollController.value * 1.6,
                    0,
                  ),
                  child: child,
                );
              },
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  color: TvaColors.txt3,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add TickerBar to AppShell**

In `app_shell.dart`, replace the `_SessionInfoBar` with a `TickerBar` placed between the masthead and the session info bar. The ticker should show session metadata.

Add between Masthead and SessionInfoBar in the desktop Column:

```dart
Consumer(builder: (context, ref, _) {
  final meta = ref.watch(sessionMetaProvider);
  final model = meta.model?.replaceAll('[1m]', '') ?? 'OPUS 4.6';
  final perm = meta.permissionMode ?? 'DEFAULT';
  return TickerBar(
    text: 'SESSION ACTIVE -- MODEL: ${model.toUpperCase()} -- CLAWD STATUS: NOMINAL -- PERMISSION MODE: ${perm.toUpperCase()}',
  );
}),
Container(height: 1, color: TvaColors.brd),
```

Add import: `import 'ticker_bar.dart';`

- [ ] **Step 3: Verify and commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/ticker_bar.dart pinch/lib/widgets/app_shell.dart
git commit -m "feat(pinch): add scrolling ticker bar below masthead"
```

---

### Task 11: Token Flash Effect

When token count or cost updates, briefly flash the values amber.

**Files:**
- Modify: `pinch/lib/widgets/masthead.dart`

- [ ] **Step 1: Add flash animation to token/cost displays**

Convert the token count and cost Text widgets to use a flash effect. Track previous values and trigger a brief amber flash when they change.

Create a `_FlashText` helper widget inside masthead.dart:

```dart
class _FlashText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color flashColor;

  const _FlashText({
    required this.text,
    required this.baseStyle,
    this.flashColor = TvaColors.amber,
  });

  @override
  State<_FlashText> createState() => _FlashTextState();
}

class _FlashTextState extends State<_FlashText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _prevText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _prevText = widget.text;
  }

  @override
  void didUpdateWidget(_FlashText old) {
    super.didUpdateWidget(old);
    if (widget.text != _prevText) {
      _prevText = widget.text;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isFlashing = _controller.isAnimating;
        return Text(
          widget.text,
          style: widget.baseStyle.copyWith(
            color: isFlashing ? widget.flashColor : widget.baseStyle.color,
          ),
        );
      },
    );
  }
}
```

Replace the token count and cost `Text` widgets with `_FlashText`.

- [ ] **Step 2: Verify and commit**

Run app, send a prompt. When tokens/cost update, they should briefly flash amber then return to normal color.

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/masthead.dart
git commit -m "feat(pinch): add amber flash effect on token/cost updates"
```

---

### Task 12: Sidebar State Sync

Active session dot in the sidebar should change color/style based on Clawd state (error → rust, success → green, active → orange pulsing).

**Files:**
- Modify: `pinch/lib/widgets/sidebar.dart`

- [ ] **Step 1: Read current sidebar.dart**

Read the file to understand the current session list rendering.

- [ ] **Step 2: Add Clawd state awareness to active session dot**

The active session's dot should reflect the current Clawd state. Watch `clawdStateProvider` and map states to colors:
- `error` → rust color, no pulse
- `success` → green-br, no pulse  
- `reading/editing/bash/typing` → orange with pulse
- `idle/thinking` → amber, no pulse

This is a targeted change to the active session item's dot rendering.

- [ ] **Step 3: Update sidebar meta text**

The active session's meta text should show the current Clawd state name (e.g., "2m -- reading files", "5m -- editing code").

- [ ] **Step 4: Verify and commit**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/sidebar.dart
git commit -m "feat(pinch): sync sidebar active session dot with Clawd state"
```

---

### Task 13: Historical Clawd Space Collapse

When a message is no longer active (historical), the Clawd area should animate to zero height. This is handled by the walk controller from Task 1, but verify the collapse animation is smooth (600ms ease-out matching mockup's `clawd-space-collapse`).

**Files:**
- Modify: `pinch/lib/widgets/timeline/claude_message.dart` (if needed)

- [ ] **Step 1: Verify collapse works from Task 1**

Run the app with multiple Claude messages. The Clawd space on old messages should smoothly collapse after the walk-off. If it already works from Task 1, this task is complete.

- [ ] **Step 2: Tune timing if needed**

The mockup uses: `width: 100→0, min-height: 44→0, margin: 6px→0` over 600ms with ease-out and 100ms delay. Adjust the collapse animation in `_buildClawdArea` if the timing doesn't match.

- [ ] **Step 3: Commit if changes were made**

```bash
cd ~/Developer/ClaudeCode && git add pinch/lib/widgets/timeline/claude_message.dart
git commit -m "fix(pinch): tune historical Clawd space collapse animation"
```
