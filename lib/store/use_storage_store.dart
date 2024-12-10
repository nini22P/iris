import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/storage_state.dart';
import 'package:iris/store/persistent_store.dart';

class StorageStore extends PersistentStore<StorageState> {
  StorageStore() : super(StorageState());

  Future<void> addStorage(Storage storage) async {
    set(state.copyWith(storages: [...state.storages, storage]));
    save(state);
  }

  Future<void> updateStorage(int index, Storage storage) async {
    if (index < 0 || index >= state.storages.length) {
      return;
    }

    final updatedStorages = state.storages
      ..removeAt(index)
      ..insert(index, storage);

    set(state.copyWith(storages: updatedStorages));
    save(state);
  }

  Future<void> removeStorage(int index) async {
    if (index < 0 || index >= state.storages.length) {
      return;
    }

    final updatedStorages = state.storages..removeAt(index);

    set(state.copyWith(storages: updatedStorages));
    save(state);
  }

  Future<void> addFavoriteStorage(Storage favoriteStorages) async {
    set(state.copyWith(
        favoriteStorages: [...state.favoriteStorages, favoriteStorages]));
    save(state);
  }

  Future<void> updateFavoriteStorage(
      int index, Storage favoriteStorages) async {
    if (index < 0 || index >= state.favoriteStorages.length) {
      return;
    }

    final updatedStorages = state.favoriteStorages
      ..removeAt(index)
      ..insert(index, favoriteStorages);

    set(state.copyWith(favoriteStorages: updatedStorages));
    save(state);
  }

  Future<void> removeFavoriteStorage(int index) async {
    if (index < 0 || index >= state.favoriteStorages.length) {
      return;
    }

    final updatedStorages = state.favoriteStorages..removeAt(index);

    set(state.copyWith(favoriteStorages: updatedStorages));
    save(state);
  }

  Future<void> updateCurrentStorage(Storage? storage) async {
    set(state.copyWith(
        currentStorage: storage, clearCurrentStorage: storage == null));
    save(state);
  }

  Future<void> updateCurrentPath(List<String>? path) async {
    set(state.copyWith(currentPath: path));
    save(state);
  }

  @override
  Future<StorageState?> load() async {
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
      log('Error loading StorageState: $e');
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
      log('Error saving StorageState: $e');
    }
  }
}

StorageStore useStorageStore() => create(() => StorageStore());
