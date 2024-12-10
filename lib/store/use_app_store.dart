import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/store/persistent_store.dart';

class AppStore extends PersistentStore<AppState> {
  AppStore() : super(AppState());

  Future<void> updateAutoPlay(bool autoPlay) async =>
      set(state.copyWith(autoPlay: autoPlay));

  Future<void> toggleMaximize() async {
    set(state.copyWith(isMaximized: !state.isMaximized));
  }

  Future<void> toggleFullScreen() async =>
      set(state.copyWith(isFullScreen: !state.isFullScreen));

  @override
  Future<AppState?> load() async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? appState = await storage.read(key: 'app_state');
      if (appState != null) {
        return AppState.fromJson(json.decode(appState)).copyWith(
          autoPlay: false,
          isFullScreen: false,
          isMaximized: false,
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

      await storage.write(key: 'app_state', value: json.encode(state.toJson()));
    } catch (e) {
      log('Error saving AppState: $e');
    }
  }
}

AppStore useAppStore() => create(() => AppStore());
