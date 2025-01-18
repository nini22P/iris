import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:iris/models/file.dart';

part 'play_queue_state.freezed.dart';
part 'play_queue_state.g.dart';

@freezed
class PlayQueueState with _$PlayQueueState {
  const factory PlayQueueState({
    @Default([]) List<PlayQueueItem> playQueue,
    @Default(0) int currentIndex,
  }) = _PlayQueueState;

  factory PlayQueueState.fromJson(Map<String, dynamic> json) =>
      _$PlayQueueStateFromJson(json);
}
