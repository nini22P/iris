import 'package:hive/hive.dart';

part 'media_info.g.dart';

@HiveType(typeId: 1)
class MediaInfo {
  @HiveField(0)
  final Duration position;

  @HiveField(1)
  final Duration duration;

  MediaInfo({
    required this.position,
    required this.duration,
  });
}
