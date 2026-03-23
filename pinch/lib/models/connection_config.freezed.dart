// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ConnectionConfig _$ConnectionConfigFromJson(Map<String, dynamic> json) {
  return _ConnectionConfig.fromJson(json);
}

/// @nodoc
mixin _$ConnectionConfig {
  String get host => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  String? get authToken => throw _privateConstructorUsedError;
  bool get autoDiscover => throw _privateConstructorUsedError;

  /// Serializes this ConnectionConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionConfigCopyWith<ConnectionConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionConfigCopyWith<$Res> {
  factory $ConnectionConfigCopyWith(
    ConnectionConfig value,
    $Res Function(ConnectionConfig) then,
  ) = _$ConnectionConfigCopyWithImpl<$Res, ConnectionConfig>;
  @useResult
  $Res call({String host, int port, String? authToken, bool autoDiscover});
}

/// @nodoc
class _$ConnectionConfigCopyWithImpl<$Res, $Val extends ConnectionConfig>
    implements $ConnectionConfigCopyWith<$Res> {
  _$ConnectionConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? port = null,
    Object? authToken = freezed,
    Object? autoDiscover = null,
  }) {
    return _then(
      _value.copyWith(
            host: null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            authToken: freezed == authToken
                ? _value.authToken
                : authToken // ignore: cast_nullable_to_non_nullable
                      as String?,
            autoDiscover: null == autoDiscover
                ? _value.autoDiscover
                : autoDiscover // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConnectionConfigImplCopyWith<$Res>
    implements $ConnectionConfigCopyWith<$Res> {
  factory _$$ConnectionConfigImplCopyWith(
    _$ConnectionConfigImpl value,
    $Res Function(_$ConnectionConfigImpl) then,
  ) = __$$ConnectionConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String host, int port, String? authToken, bool autoDiscover});
}

/// @nodoc
class __$$ConnectionConfigImplCopyWithImpl<$Res>
    extends _$ConnectionConfigCopyWithImpl<$Res, _$ConnectionConfigImpl>
    implements _$$ConnectionConfigImplCopyWith<$Res> {
  __$$ConnectionConfigImplCopyWithImpl(
    _$ConnectionConfigImpl _value,
    $Res Function(_$ConnectionConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? port = null,
    Object? authToken = freezed,
    Object? autoDiscover = null,
  }) {
    return _then(
      _$ConnectionConfigImpl(
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        authToken: freezed == authToken
            ? _value.authToken
            : authToken // ignore: cast_nullable_to_non_nullable
                  as String?,
        autoDiscover: null == autoDiscover
            ? _value.autoDiscover
            : autoDiscover // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionConfigImpl implements _ConnectionConfig {
  const _$ConnectionConfigImpl({
    required this.host,
    required this.port,
    this.authToken,
    this.autoDiscover = false,
  });

  factory _$ConnectionConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionConfigImplFromJson(json);

  @override
  final String host;
  @override
  final int port;
  @override
  final String? authToken;
  @override
  @JsonKey()
  final bool autoDiscover;

  @override
  String toString() {
    return 'ConnectionConfig(host: $host, port: $port, authToken: $authToken, autoDiscover: $autoDiscover)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionConfigImpl &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.authToken, authToken) ||
                other.authToken == authToken) &&
            (identical(other.autoDiscover, autoDiscover) ||
                other.autoDiscover == autoDiscover));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, host, port, authToken, autoDiscover);

  /// Create a copy of ConnectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionConfigImplCopyWith<_$ConnectionConfigImpl> get copyWith =>
      __$$ConnectionConfigImplCopyWithImpl<_$ConnectionConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionConfigImplToJson(this);
  }
}

abstract class _ConnectionConfig implements ConnectionConfig {
  const factory _ConnectionConfig({
    required final String host,
    required final int port,
    final String? authToken,
    final bool autoDiscover,
  }) = _$ConnectionConfigImpl;

  factory _ConnectionConfig.fromJson(Map<String, dynamic> json) =
      _$ConnectionConfigImpl.fromJson;

  @override
  String get host;
  @override
  int get port;
  @override
  String? get authToken;
  @override
  bool get autoDiscover;

  /// Create a copy of ConnectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionConfigImplCopyWith<_$ConnectionConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
