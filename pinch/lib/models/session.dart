import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

enum SessionStatus { active, idle, ended }

@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required String projectId,
    required String name,
    required SessionStatus status,
    required DateTime createdAt,
    String? model,
    int? totalTokens,
    double? cost,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}
