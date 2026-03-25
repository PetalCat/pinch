// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionOptionsImpl _$$SessionOptionsImplFromJson(Map<String, dynamic> json) =>
    _$SessionOptionsImpl(
      projectDir: json['projectDir'] as String,
      model: json['model'] as String?,
      permissionMode: json['permissionMode'] as String?,
      dangerouslySkipPermissions:
          json['dangerouslySkipPermissions'] as bool? ?? false,
      allowDangerouslySkipPermissions:
          json['allowDangerouslySkipPermissions'] as bool? ?? false,
      allowedTools:
          (json['allowedTools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      disallowedTools:
          (json['disallowedTools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      systemPrompt: json['systemPrompt'] as String?,
      appendSystemPrompt: json['appendSystemPrompt'] as String?,
      effort: json['effort'] as String?,
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      addDirs:
          (json['addDirs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mcpConfig: json['mcpConfig'] as String?,
      worktree: json['worktree'] as bool? ?? false,
      sessionName: json['sessionName'] as String?,
      resumeSessionId: json['resumeSessionId'] as String?,
    );

Map<String, dynamic> _$$SessionOptionsImplToJson(
  _$SessionOptionsImpl instance,
) => <String, dynamic>{
  'projectDir': instance.projectDir,
  'model': instance.model,
  'permissionMode': instance.permissionMode,
  'dangerouslySkipPermissions': instance.dangerouslySkipPermissions,
  'allowDangerouslySkipPermissions': instance.allowDangerouslySkipPermissions,
  'allowedTools': instance.allowedTools,
  'disallowedTools': instance.disallowedTools,
  'systemPrompt': instance.systemPrompt,
  'appendSystemPrompt': instance.appendSystemPrompt,
  'effort': instance.effort,
  'maxBudget': instance.maxBudget,
  'addDirs': instance.addDirs,
  'mcpConfig': instance.mcpConfig,
  'worktree': instance.worktree,
  'sessionName': instance.sessionName,
  'resumeSessionId': instance.resumeSessionId,
};
