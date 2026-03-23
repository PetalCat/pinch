// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) =>
    _$SessionImpl(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      model: json['model'] as String?,
      totalTokens: (json['totalTokens'] as num?)?.toInt(),
      cost: (json['cost'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'model': instance.model,
      'totalTokens': instance.totalTokens,
      'cost': instance.cost,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.idle: 'idle',
  SessionStatus.ended: 'ended',
};
