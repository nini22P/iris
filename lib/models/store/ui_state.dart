import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'ui_state.freezed.dart';
part 'ui_state.g.dart';

@freezed
abstract class UiState with _$UiState {
  const factory UiState({
    @Default(false) bool isAlwaysOnTop,
    @Default(false) bool isFullScreen,
    @Default(false) bool isPlayerExpanded,
  }) = _UiState;

  factory UiState.fromJson(Map<String, dynamic> json) =>
      _$UiStateFromJson(json);
}
