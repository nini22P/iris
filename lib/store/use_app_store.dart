import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/persistent_store.dart';

class AppStore extends PersistentStore<AppState> {
  AppStore() : super(AppState());

  Future<void> updateAutoPlay(bool autoPlay) async =>
      set(state.copyWith(autoPlay: autoPlay));

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

  Future<void> showPlayer() async => set(state.copyWith(isShowPlayer: true));

  Future<void> hidePlayer() async => set(state.copyWith(isShowPlayer: false));

  Future<void> toggleIsShowPlayer() async =>
      set(state.copyWith(isShowPlayer: !state.isShowPlayer));

  Future<void> toggleMaximize() async =>
      set(state.copyWith(isMaximized: !state.isMaximized));

  Future<void> toggleFullScreen() async =>
      set(state.copyWith(isFullScreen: !state.isFullScreen));

  @override
  Future<AppState?> load() async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? appState = await storage.read(key: 'appState');
      if (appState != null) {
        log('Loaded AppState');
        return AppState.fromJson(json.decode(appState)).copyWith(
          autoPlay: false,
          isFullScreen: false,
        );
      }
    } catch (e) {
      log('Error loading AppState: $e');
    }
    return null;
  }

  @override
  Future<void> save(AppState state) async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      await storage.write(key: 'appState', value: json.encode(state.toJson()));
      log('Saved AppState');
    } catch (e) {
      log('Error saving AppState: $e');
    }
  }
}

AppStore useAppStore() => create(() => AppStore());
