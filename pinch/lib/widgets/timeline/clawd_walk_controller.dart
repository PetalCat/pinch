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
  bool get isTransitioning => _isTransitioning;

  ClawdVisibility visibilityFor(int index) {
    if (index == _departingIndex) return ClawdVisibility.departing;
    if (index == _activeIndex) {
      return _isTransitioning ? ClawdVisibility.arriving : ClawdVisibility.active;
    }
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

      _walkTimer = Timer(_walkDuration, () {
        _departingIndex = null;
        notifyListeners();

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
