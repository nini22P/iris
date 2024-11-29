import 'package:iris/models/file.dart';

class PlayQueueState {
  List<FileItem> playQueue;
  int currentIndex;

  PlayQueueState({
    this.playQueue = const [],
    this.currentIndex = 0,
  });

  PlayQueueState copyWith({
    List<FileItem>? playQueue,
    int? currentIndex,
  }) =>
      PlayQueueState(
        playQueue: playQueue ?? this.playQueue,
        currentIndex: currentIndex ?? this.currentIndex,
      );

  Map<String, dynamic> toJson() {
    return {
      'playQueue': playQueue.map((e) => e.toJson()).toList(),
      'currentIndex': currentIndex,
    };
  }

  factory PlayQueueState.fromJson(Map<String, dynamic> json) => PlayQueueState(
        playQueue: (json['playQueue'] as List<dynamic>)
            .map((e) => FileItem.fromJson(e as Map<String, dynamic>))
            .toList()
            .cast<FileItem>(),
        currentIndex: json['currentIndex'] as int,
      );
}
