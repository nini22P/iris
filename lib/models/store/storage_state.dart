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
      'currentPath': currentPath,
    };
  }

  factory StorageState.fromJson(Map<String, dynamic> json) {
    Storage? createStorageFromJson(Map<String, dynamic> storageJson) {
      StorageType type = StorageTypeExtension.fromString(storageJson['type']);
      switch (type) {
        case StorageType.webdav:
          return WebdavStorage.fromJson(storageJson);
        case StorageType.local:
          return LocalStorage.fromJson(storageJson);
      }
    }

    List<Storage> parseStorages(List<dynamic> storageList) {
      return storageList
          .map((storageJson) => createStorageFromJson(storageJson))
          .toList()
          .cast<Storage>();
    }

    return StorageState(
      storages: json['storages'] is List ? parseStorages(json['storages']) : [],
      favoriteStorages: json['favoriteStorages'] is List
          ? parseStorages(json['favoriteStorages'])
          : [],
      currentStorage: json['currentStorage'] != null
          ? createStorageFromJson(json['currentStorage'])
          : null,
      currentPath: json['currentPath'] is List
          ? List<String>.from(json['currentPath'])
          : [],
    );
  }
}
