// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      directory: json['directory'] as String,
      shortCode: json['shortCode'] as String?,
      hasSpecs: json['hasSpecs'] as bool? ?? false,
      hasPlans: json['hasPlans'] as bool? ?? false,
      hasBrainstorm: json['hasBrainstorm'] as bool? ?? false,
      hasFindings: json['hasFindings'] as bool? ?? false,
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'directory': instance.directory,
      'shortCode': instance.shortCode,
      'hasSpecs': instance.hasSpecs,
      'hasPlans': instance.hasPlans,
      'hasBrainstorm': instance.hasBrainstorm,
      'hasFindings': instance.hasFindings,
    };
