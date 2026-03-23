import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

enum DocCategory { spec, plan, finding, brainstorm }

@freezed
class Document with _$Document {
  const factory Document({
    required String path,
    required String title,
    required DocCategory category,
    DateTime? date,
    String? docId,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
