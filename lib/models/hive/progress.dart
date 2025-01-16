import 'package:hive/hive.dart';

part 'progress.g.dart';

@HiveType(typeId: 1)
class Progress {
  @HiveField(0)
  final Duration position;

  @HiveField(1)
  final Duration duration;

  Progress({
    required this.position,
    required this.duration,
  });
}
