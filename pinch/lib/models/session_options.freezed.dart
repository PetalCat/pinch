// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SessionOptions _$SessionOptionsFromJson(Map<String, dynamic> json) {
  return _SessionOptions.fromJson(json);
}

/// @nodoc
mixin _$SessionOptions {
  String get projectDir => throw _privateConstructorUsedError;
  String? get model => throw _privateConstructorUsedError;
  String? get permissionMode => throw _privateConstructorUsedError;
  bool get dangerouslySkipPermissions => throw _privateConstructorUsedError;
  bool get allowDangerouslySkipPermissions =>
      throw _privateConstructorUsedError;
  List<String> get allowedTools => throw _privateConstructorUsedError;
  List<String> get disallowedTools => throw _privateConstructorUsedError;
  String? get systemPrompt => throw _privateConstructorUsedError;
  String? get appendSystemPrompt => throw _privateConstructorUsedError;
  String? get effort => throw _privateConstructorUsedError;
  double? get maxBudget => throw _privateConstructorUsedError;
  List<String> get addDirs => throw _privateConstructorUsedError;
  String? get mcpConfig => throw _privateConstructorUsedError;
  bool get worktree => throw _privateConstructorUsedError;
  String? get sessionName => throw _privateConstructorUsedError;

  /// Serializes this SessionOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionOptionsCopyWith<SessionOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionOptionsCopyWith<$Res> {
  factory $SessionOptionsCopyWith(
    SessionOptions value,
    $Res Function(SessionOptions) then,
  ) = _$SessionOptionsCopyWithImpl<$Res, SessionOptions>;
  @useResult
  $Res call({
    String projectDir,
    String? model,
    String? permissionMode,
    bool dangerouslySkipPermissions,
    bool allowDangerouslySkipPermissions,
    List<String> allowedTools,
    List<String> disallowedTools,
    String? systemPrompt,
    String? appendSystemPrompt,
    String? effort,
    double? maxBudget,
    List<String> addDirs,
    String? mcpConfig,
    bool worktree,
    String? sessionName,
  });
}

/// @nodoc
class _$SessionOptionsCopyWithImpl<$Res, $Val extends SessionOptions>
    implements $SessionOptionsCopyWith<$Res> {
  _$SessionOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectDir = null,
    Object? model = freezed,
    Object? permissionMode = freezed,
    Object? dangerouslySkipPermissions = null,
    Object? allowDangerouslySkipPermissions = null,
    Object? allowedTools = null,
    Object? disallowedTools = null,
    Object? systemPrompt = freezed,
    Object? appendSystemPrompt = freezed,
    Object? effort = freezed,
    Object? maxBudget = freezed,
    Object? addDirs = null,
    Object? mcpConfig = freezed,
    Object? worktree = null,
    Object? sessionName = freezed,
  }) {
    return _then(
      _value.copyWith(
            projectDir: null == projectDir
                ? _value.projectDir
                : projectDir // ignore: cast_nullable_to_non_nullable
                      as String,
            model: freezed == model
                ? _value.model
                : model // ignore: cast_nullable_to_non_nullable
                      as String?,
            permissionMode: freezed == permissionMode
                ? _value.permissionMode
                : permissionMode // ignore: cast_nullable_to_non_nullable
                      as String?,
            dangerouslySkipPermissions: null == dangerouslySkipPermissions
                ? _value.dangerouslySkipPermissions
                : dangerouslySkipPermissions // ignore: cast_nullable_to_non_nullable
                      as bool,
            allowDangerouslySkipPermissions:
                null == allowDangerouslySkipPermissions
                ? _value.allowDangerouslySkipPermissions
                : allowDangerouslySkipPermissions // ignore: cast_nullable_to_non_nullable
                      as bool,
            allowedTools: null == allowedTools
                ? _value.allowedTools
                : allowedTools // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            disallowedTools: null == disallowedTools
                ? _value.disallowedTools
                : disallowedTools // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            systemPrompt: freezed == systemPrompt
                ? _value.systemPrompt
                : systemPrompt // ignore: cast_nullable_to_non_nullable
                      as String?,
            appendSystemPrompt: freezed == appendSystemPrompt
                ? _value.appendSystemPrompt
                : appendSystemPrompt // ignore: cast_nullable_to_non_nullable
                      as String?,
            effort: freezed == effort
                ? _value.effort
                : effort // ignore: cast_nullable_to_non_nullable
                      as String?,
            maxBudget: freezed == maxBudget
                ? _value.maxBudget
                : maxBudget // ignore: cast_nullable_to_non_nullable
                      as double?,
            addDirs: null == addDirs
                ? _value.addDirs
                : addDirs // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            mcpConfig: freezed == mcpConfig
                ? _value.mcpConfig
                : mcpConfig // ignore: cast_nullable_to_non_nullable
                      as String?,
            worktree: null == worktree
                ? _value.worktree
                : worktree // ignore: cast_nullable_to_non_nullable
                      as bool,
            sessionName: freezed == sessionName
                ? _value.sessionName
                : sessionName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionOptionsImplCopyWith<$Res>
    implements $SessionOptionsCopyWith<$Res> {
  factory _$$SessionOptionsImplCopyWith(
    _$SessionOptionsImpl value,
    $Res Function(_$SessionOptionsImpl) then,
  ) = __$$SessionOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String projectDir,
    String? model,
    String? permissionMode,
    bool dangerouslySkipPermissions,
    bool allowDangerouslySkipPermissions,
    List<String> allowedTools,
    List<String> disallowedTools,
    String? systemPrompt,
    String? appendSystemPrompt,
    String? effort,
    double? maxBudget,
    List<String> addDirs,
    String? mcpConfig,
    bool worktree,
    String? sessionName,
  });
}

/// @nodoc
class __$$SessionOptionsImplCopyWithImpl<$Res>
    extends _$SessionOptionsCopyWithImpl<$Res, _$SessionOptionsImpl>
    implements _$$SessionOptionsImplCopyWith<$Res> {
  __$$SessionOptionsImplCopyWithImpl(
    _$SessionOptionsImpl _value,
    $Res Function(_$SessionOptionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectDir = null,
    Object? model = freezed,
    Object? permissionMode = freezed,
    Object? dangerouslySkipPermissions = null,
    Object? allowDangerouslySkipPermissions = null,
    Object? allowedTools = null,
    Object? disallowedTools = null,
    Object? systemPrompt = freezed,
    Object? appendSystemPrompt = freezed,
    Object? effort = freezed,
    Object? maxBudget = freezed,
    Object? addDirs = null,
    Object? mcpConfig = freezed,
    Object? worktree = null,
    Object? sessionName = freezed,
  }) {
    return _then(
      _$SessionOptionsImpl(
        projectDir: null == projectDir
            ? _value.projectDir
            : projectDir // ignore: cast_nullable_to_non_nullable
                  as String,
        model: freezed == model
            ? _value.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String?,
        permissionMode: freezed == permissionMode
            ? _value.permissionMode
            : permissionMode // ignore: cast_nullable_to_non_nullable
                  as String?,
        dangerouslySkipPermissions: null == dangerouslySkipPermissions
            ? _value.dangerouslySkipPermissions
            : dangerouslySkipPermissions // ignore: cast_nullable_to_non_nullable
                  as bool,
        allowDangerouslySkipPermissions: null == allowDangerouslySkipPermissions
            ? _value.allowDangerouslySkipPermissions
            : allowDangerouslySkipPermissions // ignore: cast_nullable_to_non_nullable
                  as bool,
        allowedTools: null == allowedTools
            ? _value._allowedTools
            : allowedTools // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        disallowedTools: null == disallowedTools
            ? _value._disallowedTools
            : disallowedTools // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        systemPrompt: freezed == systemPrompt
            ? _value.systemPrompt
            : systemPrompt // ignore: cast_nullable_to_non_nullable
                  as String?,
        appendSystemPrompt: freezed == appendSystemPrompt
            ? _value.appendSystemPrompt
            : appendSystemPrompt // ignore: cast_nullable_to_non_nullable
                  as String?,
        effort: freezed == effort
            ? _value.effort
            : effort // ignore: cast_nullable_to_non_nullable
                  as String?,
        maxBudget: freezed == maxBudget
            ? _value.maxBudget
            : maxBudget // ignore: cast_nullable_to_non_nullable
                  as double?,
        addDirs: null == addDirs
            ? _value._addDirs
            : addDirs // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        mcpConfig: freezed == mcpConfig
            ? _value.mcpConfig
            : mcpConfig // ignore: cast_nullable_to_non_nullable
                  as String?,
        worktree: null == worktree
            ? _value.worktree
            : worktree // ignore: cast_nullable_to_non_nullable
                  as bool,
        sessionName: freezed == sessionName
            ? _value.sessionName
            : sessionName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionOptionsImpl implements _SessionOptions {
  const _$SessionOptionsImpl({
    required this.projectDir,
    this.model,
    this.permissionMode,
    this.dangerouslySkipPermissions = false,
    this.allowDangerouslySkipPermissions = false,
    final List<String> allowedTools = const [],
    final List<String> disallowedTools = const [],
    this.systemPrompt,
    this.appendSystemPrompt,
    this.effort,
    this.maxBudget,
    final List<String> addDirs = const [],
    this.mcpConfig,
    this.worktree = false,
    this.sessionName,
  }) : _allowedTools = allowedTools,
       _disallowedTools = disallowedTools,
       _addDirs = addDirs;

  factory _$SessionOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionOptionsImplFromJson(json);

  @override
  final String projectDir;
  @override
  final String? model;
  @override
  final String? permissionMode;
  @override
  @JsonKey()
  final bool dangerouslySkipPermissions;
  @override
  @JsonKey()
  final bool allowDangerouslySkipPermissions;
  final List<String> _allowedTools;
  @override
  @JsonKey()
  List<String> get allowedTools {
    if (_allowedTools is EqualUnmodifiableListView) return _allowedTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedTools);
  }

  final List<String> _disallowedTools;
  @override
  @JsonKey()
  List<String> get disallowedTools {
    if (_disallowedTools is EqualUnmodifiableListView) return _disallowedTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disallowedTools);
  }

  @override
  final String? systemPrompt;
  @override
  final String? appendSystemPrompt;
  @override
  final String? effort;
  @override
  final double? maxBudget;
  final List<String> _addDirs;
  @override
  @JsonKey()
  List<String> get addDirs {
    if (_addDirs is EqualUnmodifiableListView) return _addDirs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_addDirs);
  }

  @override
  final String? mcpConfig;
  @override
  @JsonKey()
  final bool worktree;
  @override
  final String? sessionName;

  @override
  String toString() {
    return 'SessionOptions(projectDir: $projectDir, model: $model, permissionMode: $permissionMode, dangerouslySkipPermissions: $dangerouslySkipPermissions, allowDangerouslySkipPermissions: $allowDangerouslySkipPermissions, allowedTools: $allowedTools, disallowedTools: $disallowedTools, systemPrompt: $systemPrompt, appendSystemPrompt: $appendSystemPrompt, effort: $effort, maxBudget: $maxBudget, addDirs: $addDirs, mcpConfig: $mcpConfig, worktree: $worktree, sessionName: $sessionName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionOptionsImpl &&
            (identical(other.projectDir, projectDir) ||
                other.projectDir == projectDir) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.permissionMode, permissionMode) ||
                other.permissionMode == permissionMode) &&
            (identical(
                  other.dangerouslySkipPermissions,
                  dangerouslySkipPermissions,
                ) ||
                other.dangerouslySkipPermissions ==
                    dangerouslySkipPermissions) &&
            (identical(
                  other.allowDangerouslySkipPermissions,
                  allowDangerouslySkipPermissions,
                ) ||
                other.allowDangerouslySkipPermissions ==
                    allowDangerouslySkipPermissions) &&
            const DeepCollectionEquality().equals(
              other._allowedTools,
              _allowedTools,
            ) &&
            const DeepCollectionEquality().equals(
              other._disallowedTools,
              _disallowedTools,
            ) &&
            (identical(other.systemPrompt, systemPrompt) ||
                other.systemPrompt == systemPrompt) &&
            (identical(other.appendSystemPrompt, appendSystemPrompt) ||
                other.appendSystemPrompt == appendSystemPrompt) &&
            (identical(other.effort, effort) || other.effort == effort) &&
            (identical(other.maxBudget, maxBudget) ||
                other.maxBudget == maxBudget) &&
            const DeepCollectionEquality().equals(other._addDirs, _addDirs) &&
            (identical(other.mcpConfig, mcpConfig) ||
                other.mcpConfig == mcpConfig) &&
            (identical(other.worktree, worktree) ||
                other.worktree == worktree) &&
            (identical(other.sessionName, sessionName) ||
                other.sessionName == sessionName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    projectDir,
    model,
    permissionMode,
    dangerouslySkipPermissions,
    allowDangerouslySkipPermissions,
    const DeepCollectionEquality().hash(_allowedTools),
    const DeepCollectionEquality().hash(_disallowedTools),
    systemPrompt,
    appendSystemPrompt,
    effort,
    maxBudget,
    const DeepCollectionEquality().hash(_addDirs),
    mcpConfig,
    worktree,
    sessionName,
  );

  /// Create a copy of SessionOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionOptionsImplCopyWith<_$SessionOptionsImpl> get copyWith =>
      __$$SessionOptionsImplCopyWithImpl<_$SessionOptionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionOptionsImplToJson(this);
  }
}

abstract class _SessionOptions implements SessionOptions {
  const factory _SessionOptions({
    required final String projectDir,
    final String? model,
    final String? permissionMode,
    final bool dangerouslySkipPermissions,
    final bool allowDangerouslySkipPermissions,
    final List<String> allowedTools,
    final List<String> disallowedTools,
    final String? systemPrompt,
    final String? appendSystemPrompt,
    final String? effort,
    final double? maxBudget,
    final List<String> addDirs,
    final String? mcpConfig,
    final bool worktree,
    final String? sessionName,
  }) = _$SessionOptionsImpl;

  factory _SessionOptions.fromJson(Map<String, dynamic> json) =
      _$SessionOptionsImpl.fromJson;

  @override
  String get projectDir;
  @override
  String? get model;
  @override
  String? get permissionMode;
  @override
  bool get dangerouslySkipPermissions;
  @override
  bool get allowDangerouslySkipPermissions;
  @override
  List<String> get allowedTools;
  @override
  List<String> get disallowedTools;
  @override
  String? get systemPrompt;
  @override
  String? get appendSystemPrompt;
  @override
  String? get effort;
  @override
  double? get maxBudget;
  @override
  List<String> get addDirs;
  @override
  String? get mcpConfig;
  @override
  bool get worktree;
  @override
  String? get sessionName;

  /// Create a copy of SessionOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionOptionsImplCopyWith<_$SessionOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
