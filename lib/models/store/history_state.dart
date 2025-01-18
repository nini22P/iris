import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:iris/models/progress.dart';

part 'history_state.freezed.dart';
part 'history_state.g.dart';

@freezed
class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default({}) Map<String, Progress> history,
  }) = _HistoryState;

  factory HistoryState.fromJson(Map<String, dynamic> json) =>
      _$HistoryStateFromJson(json);
}
