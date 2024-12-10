import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/storages/webdav_storage.dart';

class StorageState {
  List<Storage> storages;
  List<Storage> favoriteStorages;
  Storage? currentStorage;
  List<String> currentPath;

  StorageState({
    this.storages = const [],
    this.favoriteStorages = const [],
    this.currentStorage,
    this.currentPath = const [],
  });

  StorageState copyWith({
    List<Storage>? storages,
    List<Storage>? favoriteStorages,
    Storage? currentStorage,
    bool clearCurrentStorage = false,
    List<String>? currentPath,
  }) =>
      StorageState(
        storages: storages ?? this.storages,
        favoriteStorages: favoriteStorages ?? this.favoriteStorages,
        currentStorage:
            clearCurrentStorage ? null : currentStorage ?? this.currentStorage,
        currentPath: currentPath ?? this.currentPath,
      );

  Map<String, dynamic> toJson() {
    return {
      'storages': storages.map((s) => s.toJson()).toList(),
      'favoriteStorages': favoriteStorages.map((s) => s.toJson()).toList(),
      'currentStorage': currentStorage?.toJson(),
      'currentPath': currentPath
    };
  }

  factory StorageState.fromJson(Map<String, dynamic> json) {
    return StorageState(
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
      currentPath: List<String>.from(json['currentPath']),
    );
  }
}
