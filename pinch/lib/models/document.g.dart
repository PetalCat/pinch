// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentImpl _$$DocumentImplFromJson(Map<String, dynamic> json) =>
    _$DocumentImpl(
      path: json['path'] as String,
      title: json['title'] as String,
      category: $enumDecode(_$DocCategoryEnumMap, json['category']),
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      docId: json['docId'] as String?,
    );

Map<String, dynamic> _$$DocumentImplToJson(_$DocumentImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'title': instance.title,
      'category': _$DocCategoryEnumMap[instance.category]!,
      'date': instance.date?.toIso8601String(),
      'docId': instance.docId,
    };

const _$DocCategoryEnumMap = {
  DocCategory.spec: 'spec',
  DocCategory.plan: 'plan',
  DocCategory.finding: 'finding',
  DocCategory.brainstorm: 'brainstorm',
};
