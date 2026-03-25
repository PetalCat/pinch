import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/session_event.dart';
import '../widgets/clawd/clawd_state.dart';
import 'connection_provider.dart';

/// Currently-selected session id.
final activeSessionIdProvider = StateProvider<String?>((ref) => 's1');

/// All sessions for the current project.
final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final conn = ref.watch(connectionServiceProvider);
  return conn.getSessions('current');
});

/// History for the active session.
final sessionHistoryProvider = FutureProvider<List<SessionEvent>>((ref) async {
  final sessionId = ref.watch(activeSessionIdProvider);
  if (sessionId == null) return [];
  final conn = ref.watch(connectionServiceProvider);
  return conn.getSessionHistory(sessionId);
});

/// Maps [EventType] to [ClawdState] for the animation system.
ClawdState clawdStateFromEvent(EventType type) {
  return switch (type) {
    EventType.assistantThinking => ClawdState.thinking,
    EventType.assistantText => ClawdState.typing,
    EventType.toolUse => ClawdState.reading, // will be refined by toolName
    EventType.toolResult => ClawdState.success,
    EventType.permissionRequest => ClawdState.idle,
    EventType.error => ClawdState.error,
    EventType.sessionEnd => ClawdState.idle,
    EventType.userMessage => ClawdState.idle,
    _ => ClawdState.idle,
  };
}
