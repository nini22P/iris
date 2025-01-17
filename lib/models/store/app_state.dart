import 'package:flutter/material.dart';

enum Repeat {
  none,
  all,
  one,
}

class AppState {
  bool autoPlay;
  bool shuffle;
  Repeat repeat;
  BoxFit fit;
  int volume;
  bool isMuted;
  ThemeMode themeMode;
  String subtitleLanguage;
  String language;
  bool autoCheckUpdates;
  bool autoResize;

  AppState({
    this.autoPlay = false,
    this.shuffle = false,
    this.repeat = Repeat.none,
    this.fit = BoxFit.contain,
    this.volume = 100,
    this.isMuted = false,
    this.themeMode = ThemeMode.system,
    this.subtitleLanguage = 'auto',
    this.language = 'auto',
    this.autoCheckUpdates = false,
    this.autoResize = false,
  });

  AppState copyWith({
    bool? autoPlay,
    bool? shuffle,
    Repeat? repeat,
    BoxFit? fit,
    int? volume,
    bool? isMuted,
    ThemeMode? themeMode,
    String? subtitleLanguage,
    String? language,
    bool? autoCheckUpdates,
    bool? autoResize,
  }) =>
      AppState(
        autoPlay: autoPlay ?? this.autoPlay,
        shuffle: shuffle ?? this.shuffle,
        repeat: repeat ?? this.repeat,
        fit: fit ?? this.fit,
        volume: volume ?? this.volume,
        isMuted: isMuted ?? this.isMuted,
        themeMode: themeMode ?? this.themeMode,
        subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
        language: language ?? this.language,
        autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
        autoResize: autoResize ?? this.autoResize,
      );

  Map<String, dynamic> toJson() {
    return {
      'autoPlay': autoPlay,
      'shuffle': shuffle,
      'repeat': repeat.name,
      'fit': fit.name,
      'volume': volume,
      'isMuted': isMuted,
      'themeMode': themeMode.name,
      'subtitleLanguage': subtitleLanguage,
      'language': language,
      'autoCheckUpdates': autoCheckUpdates,
      'autoResize': autoResize,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      autoPlay: json['autoPlay'] ?? false,
      shuffle: json['shuffle'] ?? false,
      repeat: Repeat.values.firstWhere((e) => e.name == json['repeat'],
          orElse: () => Repeat.none),
      fit: BoxFit.values.firstWhere((e) => e.name == json['fit'],
          orElse: () => BoxFit.contain),
      volume: json['volume'] ?? 100,
      isMuted: json['isMuted'] ?? false,
      themeMode: ThemeMode.values.firstWhere((e) => e.name == json['themeMode'],
          orElse: () => ThemeMode.system),
      subtitleLanguage: json['subtitleLanguage'],
      language: json['language'],
      autoCheckUpdates: json['autoCheckUpdates'] ?? true,
      autoResize: json['autoResize'] ?? false,
    );
  }
}
