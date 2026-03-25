// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get directory => throw _privateConstructorUsedError;
  String? get shortCode => throw _privateConstructorUsedError;
  bool get hasSpecs => throw _privateConstructorUsedError;
  bool get hasPlans => throw _privateConstructorUsedError;
  bool get hasBrainstorm => throw _privateConstructorUsedError;
  bool get hasFindings => throw _privateConstructorUsedError;

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call({
    String id,
    String name,
    String directory,
    String? shortCode,
    bool hasSpecs,
    bool hasPlans,
    bool hasBrainstorm,
    bool hasFindings,
  });
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? directory = null,
    Object? shortCode = freezed,
    Object? hasSpecs = null,
    Object? hasPlans = null,
    Object? hasBrainstorm = null,
    Object? hasFindings = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            directory: null == directory
                ? _value.directory
                : directory // ignore: cast_nullable_to_non_nullable
                      as String,
            shortCode: freezed == shortCode
                ? _value.shortCode
                : shortCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasSpecs: null == hasSpecs
                ? _value.hasSpecs
                : hasSpecs // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasPlans: null == hasPlans
                ? _value.hasPlans
                : hasPlans // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasBrainstorm: null == hasBrainstorm
                ? _value.hasBrainstorm
                : hasBrainstorm // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasFindings: null == hasFindings
                ? _value.hasFindings
                : hasFindings // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
    _$ProjectImpl value,
    $Res Function(_$ProjectImpl) then,
  ) = __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String directory,
    String? shortCode,
    bool hasSpecs,
    bool hasPlans,
    bool hasBrainstorm,
    bool hasFindings,
  });
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
    _$ProjectImpl _value,
    $Res Function(_$ProjectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? directory = null,
    Object? shortCode = freezed,
    Object? hasSpecs = null,
    Object? hasPlans = null,
    Object? hasBrainstorm = null,
    Object? hasFindings = null,
  }) {
    return _then(
      _$ProjectImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        directory: null == directory
            ? _value.directory
            : directory // ignore: cast_nullable_to_non_nullable
                  as String,
        shortCode: freezed == shortCode
            ? _value.shortCode
            : shortCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasSpecs: null == hasSpecs
            ? _value.hasSpecs
            : hasSpecs // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasPlans: null == hasPlans
            ? _value.hasPlans
            : hasPlans // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasBrainstorm: null == hasBrainstorm
            ? _value.hasBrainstorm
            : hasBrainstorm // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasFindings: null == hasFindings
            ? _value.hasFindings
            : hasFindings // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl implements _Project {
  const _$ProjectImpl({
    required this.id,
    required this.name,
    required this.directory,
    this.shortCode,
    this.hasSpecs = false,
    this.hasPlans = false,
    this.hasBrainstorm = false,
    this.hasFindings = false,
  });

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String directory;
  @override
  final String? shortCode;
  @override
  @JsonKey()
  final bool hasSpecs;
  @override
  @JsonKey()
  final bool hasPlans;
  @override
  @JsonKey()
  final bool hasBrainstorm;
  @override
  @JsonKey()
  final bool hasFindings;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, directory: $directory, shortCode: $shortCode, hasSpecs: $hasSpecs, hasPlans: $hasPlans, hasBrainstorm: $hasBrainstorm, hasFindings: $hasFindings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.directory, directory) ||
                other.directory == directory) &&
            (identical(other.shortCode, shortCode) ||
                other.shortCode == shortCode) &&
            (identical(other.hasSpecs, hasSpecs) ||
                other.hasSpecs == hasSpecs) &&
            (identical(other.hasPlans, hasPlans) ||
                other.hasPlans == hasPlans) &&
            (identical(other.hasBrainstorm, hasBrainstorm) ||
                other.hasBrainstorm == hasBrainstorm) &&
            (identical(other.hasFindings, hasFindings) ||
                other.hasFindings == hasFindings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    directory,
    shortCode,
    hasSpecs,
    hasPlans,
    hasBrainstorm,
    hasFindings,
  );

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(this);
  }
}

abstract class _Project implements Project {
  const factory _Project({
    required final String id,
    required final String name,
    required final String directory,
    final String? shortCode,
    final bool hasSpecs,
    final bool hasPlans,
    final bool hasBrainstorm,
    final bool hasFindings,
  }) = _$ProjectImpl;

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get directory;
  @override
  String? get shortCode;
  @override
  bool get hasSpecs;
  @override
  bool get hasPlans;
  @override
  bool get hasBrainstorm;
  @override
  bool get hasFindings;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
