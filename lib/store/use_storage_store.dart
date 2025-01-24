import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/storage_state.dart';
import 'package:iris/store/persistent_store.dart';
import 'package:iris/utils/logger.dart';

class StorageStore extends PersistentStore<StorageState> {
  StorageStore() : super(StorageState());

  Storage? findById(String id) =>
      state.localStorages.firstWhereOrNull((storage) => storage.id == id) ??
      state.storages.firstWhereOrNull((storage) => storage.id == id);

  Future<void> updateLocalStorages(List<LocalStorage> storages) async {
    set(state.copyWith(localStorages: storages));
    await save(state);
  }

  Future<void> addStorage(Storage storage) async {
    set(state.copyWith(storages: [...state.storages, storage]));
    await save(state);
  }

  Future<void> updateStorage(int index, Storage storage) async {
    if (index < 0 || index >= state.storages.length) {
      return;
    }

    set(state.copyWith(
        storages: [...state.storages]
          ..removeAt(index)
          ..insert(index, storage)));
    await save(state);
  }

  Future<void> removeStorage(Storage storage) async {
    set(state.copyWith(storages: [...state.storages]..remove(storage)));
    await save(state);
  }

  Future<void> addFavorite(Favorite favorite) async {
    set(state.copyWith(favorites: [...state.favorites, favorite]));
    await save(state);
  }

  Future<void> removeFavorite(Favorite favorite) async {
    set(state.copyWith(favorites: [...state.favorites]..remove(favorite)));
    await save(state);
  }

  Future<void> updateCurrentStorage(Storage? storage) async {
    set(state.copyWith(currentStorage: storage));
    await save(state);
  }

  Future<void> updateCurrentPath(List<String> path) async {
    set(state.copyWith(currentPath: path));
    await save(state);
  }

  @override
  Future<StorageState?> load() async {
    logger('Loading StorageState');
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? storageState = await storage.read(key: 'storage_state');
      if (storageState != null) {
        return StorageState.fromJson(json.decode(storageState));
      }
    } catch (e) {
      logger('Error loading StorageState: $e');
    }
    return null;
  }

  @override
  Future<void> save(StorageState state) async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      await storage.write(
          key: 'storage_state', value: json.encode(state.toJson()));
    } catch (e) {
      logger('Error saving StorageState: $e');
    }
  }
}

StorageStore useStorageStore() => create(() => StorageStore());
