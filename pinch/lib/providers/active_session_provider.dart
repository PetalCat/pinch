import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_event.dart';
import 'clawd_state_provider.dart';
import 'connection_provider.dart';
import 'session_provider.dart';

/// Live event list for the active session.
final activeSessionEventsProvider =
    StateNotifierProvider<ActiveSessionNotifier, List<SessionEvent>>((ref) {
  return ActiveSessionNotifier(ref);
});

class ActiveSessionNotifier extends StateNotifier<List<SessionEvent>> {
  final Ref _ref;
  StreamSubscription<SessionEvent>? _sub;

  ActiveSessionNotifier(this._ref) : super([]) {
    // Listen to the connection's event stream
    final conn = _ref.read(connectionServiceProvider);
    _sub = conn.eventStream.listen((event) {
      final activeId = _ref.read(activeSessionIdProvider);
      if (activeId != null && event.sessionId == activeId) {
        state = [...state, event];
        // Update Clawd state
        _ref.read(clawdStateProvider.notifier).state =
            clawdStateFromEvent(event.type);
        // Update session meta
        _updateMeta(event);
      }
    });
  }

  void _updateMeta(SessionEvent event) {
    final current = _ref.read(sessionMetaProvider);
    int tokenDelta = 0;
    switch (event.type) {
      case EventType.assistantText:
        tokenDelta = 100; // approximate
      case EventType.toolUse:
        tokenDelta = 50;
      case EventType.toolResult:
        tokenDelta = 200;
      default:
        break;
    }
    if (tokenDelta > 0) {
      _ref.read(sessionMetaProvider.notifier).state = SessionMeta(
        elapsed: current.elapsed,
        tokens: current.tokens + tokenDelta,
        cost: (current.tokens + tokenDelta) * 0.000005,
        model: current.model,
        isResponding: event.type != EventType.assistantText ||
            event.data['done'] != true,
      );
    }
    // Update responding state
    if (event.type == EventType.assistantText && event.data['done'] == true) {
      _ref.read(sessionMetaProvider.notifier).state =
          _ref.read(sessionMetaProvider).copyWith(isResponding: false);
    } else if (event.type == EventType.userMessage) {
      _ref.read(sessionMetaProvider.notifier).state =
          _ref.read(sessionMetaProvider).copyWith(isResponding: true);
    }
  }

  void clearAndListenTo(String sessionId) {
    state = [];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Session meta — elapsed time, tokens, cost
class SessionMeta {
  final Duration elapsed;
  final int tokens;
  final double cost;
  final String? model;
  final bool isResponding;

  const SessionMeta({
    this.elapsed = Duration.zero,
    this.tokens = 0,
    this.cost = 0,
    this.model,
    this.isResponding = false,
  });

  SessionMeta copyWith({
    Duration? elapsed,
    int? tokens,
    double? cost,
    String? model,
    bool? isResponding,
  }) {
    return SessionMeta(
      elapsed: elapsed ?? this.elapsed,
      tokens: tokens ?? this.tokens,
      cost: cost ?? this.cost,
      model: model ?? this.model,
      isResponding: isResponding ?? this.isResponding,
    );
  }
}

final sessionMetaProvider =
    StateProvider<SessionMeta>((ref) => const SessionMeta());
