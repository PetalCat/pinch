// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionEventImpl _$$SessionEventImplFromJson(Map<String, dynamic> json) =>
    _$SessionEventImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecode(_$EventTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$SessionEventImplToJson(_$SessionEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$EventTypeEnumMap[instance.type]!,
      'data': instance.data,
    };

const _$EventTypeEnumMap = {
  EventType.userMessage: 'userMessage',
  EventType.assistantText: 'assistantText',
  EventType.assistantThinking: 'assistantThinking',
  EventType.toolUse: 'toolUse',
  EventType.toolResult: 'toolResult',
  EventType.permissionRequest: 'permissionRequest',
  EventType.permissionResponse: 'permissionResponse',
  EventType.error: 'error',
  EventType.sessionStart: 'sessionStart',
  EventType.sessionEnd: 'sessionEnd',
};
