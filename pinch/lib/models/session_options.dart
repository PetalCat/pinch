import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_options.freezed.dart';
part 'session_options.g.dart';

@freezed
class SessionOptions with _$SessionOptions {
  const factory SessionOptions({
    required String projectDir,
    String? model,
    String? permissionMode,
    @Default(false) bool dangerouslySkipPermissions,
    @Default(false) bool allowDangerouslySkipPermissions,
    @Default([]) List<String> allowedTools,
    @Default([]) List<String> disallowedTools,
    String? systemPrompt,
    String? appendSystemPrompt,
    String? effort,
    double? maxBudget,
    @Default([]) List<String> addDirs,
    String? mcpConfig,
    @Default(false) bool worktree,
    String? sessionName,
    String? resumeSessionId,
  }) = _SessionOptions;

  factory SessionOptions.fromJson(Map<String, dynamic> json) =>
      _$SessionOptionsFromJson(json);
}
