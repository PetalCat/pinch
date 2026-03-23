import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_config.freezed.dart';
part 'connection_config.g.dart';

@freezed
class ConnectionConfig with _$ConnectionConfig {
  const factory ConnectionConfig({
    required String host,
    required int port,
    String? authToken,
    @Default(false) bool autoDiscover,
  }) = _ConnectionConfig;

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) =>
      _$ConnectionConfigFromJson(json);
}
