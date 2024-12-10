class AppState {
  bool autoPlay;
  bool loop;
  int volume;
  bool isMaximized;
  bool isFullScreen;
  bool isMuted;
  String theme;
  String subtitleLanguage;
  bool autoCheckUpdates;

  AppState({
    this.autoPlay = false,
    this.loop = false,
    this.volume = 100,
    this.isMaximized = false,
    this.isFullScreen = false,
    this.isMuted = false,
    this.theme = 'auto',
    this.subtitleLanguage = 'auto',
    this.autoCheckUpdates = true,
  });

  AppState copyWith({
    bool? autoPlay,
    bool? loop,
    int? volume,
    bool? isMaximized,
    bool? isFullScreen,
    bool? isMuted,
    String? theme,
    String? subtitleLanguage,
    bool? autoCheckUpdates,
  }) =>
      AppState(
        autoPlay: autoPlay ?? this.autoPlay,
        loop: loop ?? this.loop,
        volume: volume ?? this.volume,
        isMaximized: isMaximized ?? this.isMaximized,
        isFullScreen: isFullScreen ?? this.isFullScreen,
        isMuted: isMuted ?? this.isMuted,
        theme: theme ?? this.theme,
        subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
        autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      );

  Map<String, dynamic> toJson() {
    return {
      'autoPlay': autoPlay,
      'loop': loop,
      'volume': volume,
      'isMaximized': isMaximized,
      'isFullScreen': isFullScreen,
      'isMuted': isMuted,
      'theme': theme,
      'subtitleLanguage': subtitleLanguage,
      'autoCheckUpdates': autoCheckUpdates,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      autoPlay: json['autoPlay'] ?? true,
      loop: json['loop'] ?? false,
      volume: json['volume'] ?? 100,
      isMaximized: json['isMaximized'] ?? false,
      isFullScreen: json['isFullScreen'] ?? false,
      isMuted: json['isMuted'] ?? false,
      theme: json['theme'] ?? 'auto',
      subtitleLanguage: json['subtitleLanguage'] ?? 'auto',
      autoCheckUpdates: json['autoCheckUpdates'] ?? true,
    );
  }
}
