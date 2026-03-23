// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConnectionConfigImpl _$$ConnectionConfigImplFromJson(
  Map<String, dynamic> json,
) => _$ConnectionConfigImpl(
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  authToken: json['authToken'] as String?,
  autoDiscover: json['autoDiscover'] as bool? ?? false,
);

Map<String, dynamic> _$$ConnectionConfigImplToJson(
  _$ConnectionConfigImpl instance,
) => <String, dynamic>{
  'host': instance.host,
  'port': instance.port,
  'authToken': instance.authToken,
  'autoDiscover': instance.autoDiscover,
};
