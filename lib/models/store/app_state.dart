class AppState {
  bool autoPlay;
  bool loop;
  int volume;
  bool isMuted;
  String theme;
  String subtitleLanguage;
  bool autoCheckUpdates;
  String language;
  bool autoResize;

  AppState({
    this.autoPlay = false,
    this.loop = false,
    this.volume = 100,
    this.isMuted = false,
    this.theme = 'auto',
    this.subtitleLanguage = 'auto',
    this.autoCheckUpdates = true,
    this.language = 'auto',
    this.autoResize = false,
  });

  AppState copyWith({
    bool? autoPlay,
    bool? loop,
    int? volume,
    bool? isMuted,
    String? theme,
    String? subtitleLanguage,
    bool? autoCheckUpdates,
    String? language,
    bool? autoResize,
  }) =>
      AppState(
        autoPlay: autoPlay ?? this.autoPlay,
        loop: loop ?? this.loop,
        volume: volume ?? this.volume,
        isMuted: isMuted ?? this.isMuted,
        theme: theme ?? this.theme,
        subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
        autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
        language: language ?? this.language,
        autoResize: autoResize ?? this.autoResize,
      );

  Map<String, dynamic> toJson() {
    return {
      'autoPlay': autoPlay,
      'loop': loop,
      'volume': volume,
      'isMuted': isMuted,
      'theme': theme,
      'subtitleLanguage': subtitleLanguage,
      'autoCheckUpdates': autoCheckUpdates,
      'language': language,
      'autoResize': autoResize,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      autoPlay: json['autoPlay'] ?? true,
      loop: json['loop'] ?? false,
      volume: json['volume'] ?? 100,
      isMuted: json['isMuted'] ?? false,
      theme: json['theme'] ?? 'auto',
      subtitleLanguage: json['subtitleLanguage'] ?? 'auto',
      autoCheckUpdates: json['autoCheckUpdates'] ?? true,
      language: json['language'] ?? 'auto',
      autoResize: json['autoResize'] ?? false,
    );
  }
}
