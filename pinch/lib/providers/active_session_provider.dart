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
  Timer? _elapsedTimer;

  ActiveSessionNotifier(this._ref) : super([]) {
    final conn = _ref.read(connectionServiceProvider);
    _sub = conn.eventStream.listen((event) {
      final activeId = _ref.read(activeSessionIdProvider);
      if (activeId != null && event.sessionId == activeId) {
        state = [...state, event];
        _ref.read(clawdStateProvider.notifier).state =
            clawdStateFromEvent(event.type);
        _updateMeta(event);
      }
    });
  }

  void _updateMeta(SessionEvent event) {
    final current = _ref.read(sessionMetaProvider);

    switch (event.type) {
      case EventType.sessionStart:
        final model = event.data['model'] as String? ?? current.model;
        final cwd = event.data['cwd'] as String?;
        final permMode = event.data['permissionMode'] as String?;
        final version = event.data['claude_code_version'] as String?;
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          model: model,
          cwd: cwd ?? current.cwd,
          permissionMode: permMode ?? current.permissionMode,
          version: version ?? current.version,
          isResponding: false,
          isEnded: false,
        );
        _startElapsedTimer();

      case EventType.userMessage:
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          isResponding: true,
        );

      case EventType.assistantText:
        // Use real token data if available
        final usage = event.data['usage'] as Map<String, dynamic>?;
        final model = event.data['model'] as String?;
        int tokens = current.tokens;
        if (usage != null) {
          tokens = (usage['input_tokens'] as int? ?? 0) +
              (usage['output_tokens'] as int? ?? 0);
        }
        final done = event.data['done'] == true;
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          tokens: tokens > current.tokens ? tokens : current.tokens,
          model: model ?? current.model,
          isResponding: !done,
        );

      case EventType.sessionEnd:
        // Real cost and tokens from the result event
        final cost = (event.data['cost'] as num?)?.toDouble() ?? current.cost;
        final totalTokens = event.data['totalTokens'] as int? ?? current.tokens;
        _stopElapsedTimer();
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          tokens: totalTokens > current.tokens ? totalTokens : current.tokens,
          cost: cost > current.cost ? cost : current.cost,
          isResponding: false,
          isEnded: true,
        );

      case EventType.turnComplete:
        // Turn finished — update cost/tokens but session stays alive
        final cost = (event.data['cost'] as num?)?.toDouble() ?? current.cost;
        final totalTokens = event.data['totalTokens'] as int? ?? current.tokens;
        final model = event.data['model'] as String?;
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          tokens: totalTokens > current.tokens ? totalTokens : current.tokens,
          cost: cost > current.cost ? cost : current.cost,
          model: model ?? current.model,
          isResponding: false,
        );

      case EventType.error:
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          isResponding: false,
        );

      default:
        break;
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final current = _ref.read(sessionMetaProvider);
      if (!current.isEnded) {
        _ref.read(sessionMetaProvider.notifier).state = current.copyWith(
          elapsed: current.elapsed + const Duration(seconds: 1),
        );
      }
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void clearAndListenTo(String sessionId) {
    _stopElapsedTimer();
    _ref.read(sessionMetaProvider.notifier).state = const SessionMeta();
    state = [];
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _stopElapsedTimer();
    super.dispose();
  }
}

/// Session meta — elapsed time, tokens, cost
class SessionMeta {
  final Duration elapsed;
  final int tokens;
  final double cost;
  final String? model;
  final String? cwd;
  final String? permissionMode;
  final String? version;
  final bool isResponding;
  final bool isEnded;

  const SessionMeta({
    this.elapsed = Duration.zero,
    this.tokens = 0,
    this.cost = 0,
    this.model,
    this.cwd,
    this.permissionMode,
    this.version,
    this.isResponding = false,
    this.isEnded = false,
  });

  SessionMeta copyWith({
    Duration? elapsed,
    int? tokens,
    double? cost,
    String? model,
    String? cwd,
    String? permissionMode,
    String? version,
    bool? isResponding,
    bool? isEnded,
  }) {
    return SessionMeta(
      elapsed: elapsed ?? this.elapsed,
      tokens: tokens ?? this.tokens,
      cost: cost ?? this.cost,
      model: model ?? this.model,
      cwd: cwd ?? this.cwd,
      permissionMode: permissionMode ?? this.permissionMode,
      version: version ?? this.version,
      isResponding: isResponding ?? this.isResponding,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}

final sessionMetaProvider =
    StateProvider<SessionMeta>((ref) => const SessionMeta());
