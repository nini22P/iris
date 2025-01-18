import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'file.freezed.dart';
part 'file.g.dart';

enum ContentType {
  dir,
  video,
  audio,
  image,
  other,
}

@freezed
abstract class FileItem implements _$FileItem {
  const FileItem._();
  const factory FileItem({
    required String storageId,
    required String name,
    required String uri,
    required List<String> path,
    required bool isDir,
    required int size,
    required ContentType type,
    String? auth,
    List<Subtitle>? subtitles,
  }) = _FileItem;

  factory FileItem.fromJson(Map<String, dynamic> json) =>
      _$FileItemFromJson(json);

  String getID() => '$storageId:${path.join('/')}';
}

@freezed
class Subtitle with _$Subtitle {
  const factory Subtitle({
    required String name,
    required String uri,
  }) = _Subtitle;

  factory Subtitle.fromJson(Map<String, dynamic> json) =>
      _$SubtitleFromJson(json);
}

@freezed
class PlayQueueItem with _$PlayQueueItem {
  const factory PlayQueueItem({
    required FileItem file,
    required int index,
  }) = _PlayQueueItem;

  factory PlayQueueItem.fromJson(Map<String, dynamic> json) =>
      _$PlayQueueItemFromJson(json);
}
