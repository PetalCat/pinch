// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SessionEvent _$SessionEventFromJson(Map<String, dynamic> json) {
  return _SessionEvent.fromJson(json);
}

/// @nodoc
mixin _$SessionEvent {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  EventType get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;

  /// Serializes this SessionEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionEventCopyWith<SessionEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionEventCopyWith<$Res> {
  factory $SessionEventCopyWith(
    SessionEvent value,
    $Res Function(SessionEvent) then,
  ) = _$SessionEventCopyWithImpl<$Res, SessionEvent>;
  @useResult
  $Res call({
    String id,
    String sessionId,
    DateTime timestamp,
    EventType type,
    Map<String, dynamic> data,
  });
}

/// @nodoc
class _$SessionEventCopyWithImpl<$Res, $Val extends SessionEvent>
    implements $SessionEventCopyWith<$Res> {
  _$SessionEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? type = null,
    Object? data = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as EventType,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionEventImplCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory _$$SessionEventImplCopyWith(
    _$SessionEventImpl value,
    $Res Function(_$SessionEventImpl) then,
  ) = __$$SessionEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sessionId,
    DateTime timestamp,
    EventType type,
    Map<String, dynamic> data,
  });
}

/// @nodoc
class __$$SessionEventImplCopyWithImpl<$Res>
    extends _$SessionEventCopyWithImpl<$Res, _$SessionEventImpl>
    implements _$$SessionEventImplCopyWith<$Res> {
  __$$SessionEventImplCopyWithImpl(
    _$SessionEventImpl _value,
    $Res Function(_$SessionEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? type = null,
    Object? data = null,
  }) {
    return _then(
      _$SessionEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as EventType,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionEventImpl implements _SessionEvent {
  const _$SessionEventImpl({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.type,
    required final Map<String, dynamic> data,
  }) : _data = data;

  factory _$SessionEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionEventImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final DateTime timestamp;
  @override
  final EventType type;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString() {
    return 'SessionEvent(id: $id, sessionId: $sessionId, timestamp: $timestamp, type: $type, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sessionId,
    timestamp,
    type,
    const DeepCollectionEquality().hash(_data),
  );

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionEventImplCopyWith<_$SessionEventImpl> get copyWith =>
      __$$SessionEventImplCopyWithImpl<_$SessionEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionEventImplToJson(this);
  }
}

abstract class _SessionEvent implements SessionEvent {
  const factory _SessionEvent({
    required final String id,
    required final String sessionId,
    required final DateTime timestamp,
    required final EventType type,
    required final Map<String, dynamic> data,
  }) = _$SessionEventImpl;

  factory _SessionEvent.fromJson(Map<String, dynamic> json) =
      _$SessionEventImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  DateTime get timestamp;
  @override
  EventType get type;
  @override
  Map<String, dynamic> get data;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionEventImplCopyWith<_$SessionEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
