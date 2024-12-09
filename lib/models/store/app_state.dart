import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/storages/webdav_storage.dart';

class AppState {
  List<Storage> storages;
  List<Storage> favoriteStorages;
  Storage? currentStorage;
  bool autoPlay;
  bool loop;
  int volume;
  bool isMaximized;
  bool isFullScreen;
  bool isMuted;
  Map<String, double> playbackProgress;
  String theme;
  String subtitleLanguage;
  bool autoCheckUpdates;

  AppState({
    this.storages = const [],
    this.favoriteStorages = const [],
    this.currentStorage,
    this.autoPlay = false,
    this.loop = false,
    this.volume = 100,
    this.isMaximized = false,
    this.isFullScreen = false,
    this.isMuted = false,
    this.playbackProgress = const {},
    this.theme = 'auto',
    this.subtitleLanguage = 'auto',
    this.autoCheckUpdates = true,
  });

  AppState copyWith({
    List<Storage>? storages,
    List<Storage>? favoriteStorages,
    Storage? currentStorage,
    bool clearCurrentStorage = false,
    bool? autoPlay,
    bool? loop,
    int? volume,
    bool? isMaximized,
    bool? isFullScreen,
    bool? isMuted,
    Map<String, double>? playbackProgress,
    String? theme,
    String? subtitleLanguage,
    bool? autoCheckUpdates,
  }) =>
      AppState(
        storages: storages ?? this.storages,
        favoriteStorages: favoriteStorages ?? this.favoriteStorages,
        currentStorage:
            clearCurrentStorage ? null : currentStorage ?? this.currentStorage,
        autoPlay: autoPlay ?? this.autoPlay,
        loop: loop ?? this.loop,
        volume: volume ?? this.volume,
        isMaximized: isMaximized ?? this.isMaximized,
        isFullScreen: isFullScreen ?? this.isFullScreen,
        isMuted: isMuted ?? this.isMuted,
        playbackProgress: playbackProgress ?? this.playbackProgress,
        theme: theme ?? this.theme,
        subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
        autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      );

  Map<String, dynamic> toJson() {
    return {
      'storages': storages.map((s) => s.toJson()).toList(),
      'favoriteStorages': favoriteStorages.map((s) => s.toJson()).toList(),
      'currentStorage': currentStorage?.toJson(),
      'autoPlay': autoPlay,
      'loop': loop,
      'volume': volume,
      'isMaximized': isMaximized,
      'isFullScreen': isFullScreen,
      'isMuted': isMuted,
      'playbackProgress': playbackProgress,
      'theme': theme,
      'subtitleLanguage': subtitleLanguage,
      'autoCheckUpdates': autoCheckUpdates,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      storages: (json['storages'] as List)
          .map((storageJson) {
            switch (storageJson['type']) {
              case 'webdav':
                return WebdavStorage.fromJson(storageJson);
              case 'local':
                return LocalStorage.fromJson(storageJson);
              default:
                throw Exception('Unknown storage type');
            }
          })
          .toList()
          .cast<Storage>(),
      favoriteStorages: (json['favoriteStorages'] as List)
          .map((storageJson) {
            switch (storageJson['type']) {
              case 'webdav':
                return WebdavStorage.fromJson(storageJson);
              case 'local':
                return LocalStorage.fromJson(storageJson);
              default:
                throw Exception('Unknown storage type');
            }
          })
          .toList()
          .cast<Storage>(),
      currentStorage: json['currentStorage'] != null
          ? (() {
              switch (json['currentStorage']['type']) {
                case 'webdav':
                  return WebdavStorage.fromJson(json['currentStorage']);
                case 'local':
                  return LocalStorage.fromJson(json['currentStorage']);
                default:
                  return null;
              }
            })()
          : null,
      autoPlay: json['autoPlay'] ?? true,
      loop: json['loop'] ?? false,
      volume: json['volume'] ?? 100,
      isMaximized: json['isMaximized'] ?? false,
      isFullScreen: json['isFullScreen'] ?? false,
      isMuted: json['isMuted'] ?? false,
      playbackProgress: Map<String, double>.from(json['playbackProgress']),
      theme: json['theme'] ?? 'auto',
      subtitleLanguage: json['subtitleLanguage'] ?? 'auto',
      autoCheckUpdates: json['autoCheckUpdates'] ?? true,
    );
  }
}
