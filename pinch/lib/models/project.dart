import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String directory,
    String? shortCode,
    @Default(false) bool hasSpecs,
    @Default(false) bool hasPlans,
    @Default(false) bool hasBrainstorm,
    @Default(false) bool hasFindings,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
