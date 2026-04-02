import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_event.freezed.dart';
part 'session_event.g.dart';

enum EventType {
  userMessage,
  assistantText,
  assistantThinking,
  toolUse,
  toolResult,
  permissionRequest,
  permissionResponse,
  error,
  sessionStart,
  sessionEnd,
  turnComplete,
}

@freezed
class SessionEvent with _$SessionEvent {
  const factory SessionEvent({
    required String id,
    required String sessionId,
    required DateTime timestamp,
    required EventType type,
    required Map<String, dynamic> data,
  }) = _SessionEvent;

  factory SessionEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionEventFromJson(json);
}
