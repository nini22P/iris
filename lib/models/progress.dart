import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:iris/models/file.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

@freezed
class Progress with _$Progress {
  const factory Progress({
    required DateTime dateTime,
    required Duration position,
    required Duration duration,
    required FileItem file,
  }) = _Progress;

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);
}
