import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_state.freezed.dart';
part 'app_state.g.dart';

enum Repeat {
  none,
  all,
  one,
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default(false) bool autoPlay,
    @Default(false) bool shuffle,
    @Default(Repeat.none) Repeat repeat,
    @Default(BoxFit.contain) BoxFit fit,
    @Default(100) int volume,
    @Default(false) bool isMuted,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('auto') String subtitleLanguage,
    @Default('auto') String language,
    @Default(false) bool autoCheckUpdates,
    @Default(false) bool autoResize,
  }) = _AppState;

  factory AppState.fromJson(Map<String, dynamic> json) =>
      _$AppStateFromJson(json);
}
