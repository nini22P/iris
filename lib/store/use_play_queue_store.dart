import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/store/play_queue_state.dart';
import 'package:iris/store/persistent_store.dart';

class PlayQueueStore extends PersistentStore<PlayQueueState> {
  PlayQueueStore() : super(PlayQueueState());

  Future<void> updatePlayQueue(
      List<FileItem> playQueue, int? currentIndex) async {
    set(state.copyWith(
      playQueue: playQueue,
      currentIndex: currentIndex ?? state.currentIndex,
    ));
    save(state);
  }

  Future<void> updateCurrentIndex(int currentIndex) async {
    set(state.copyWith(currentIndex: currentIndex));
    save(state);
  }

  @override
  Future<PlayQueueState?> load() async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? appState = await storage.read(key: 'playQueueState');
      if (appState != null) {
        log('Loaded PlayQueueState');
        return PlayQueueState.fromJson(json.decode(appState));
      }
    } catch (e) {
      log('Error loading PlayQueueState: $e');
    }
    return null;
  }

  @override
  Future<void> save(PlayQueueState state) async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      await storage.write(
          key: 'playQueueState', value: json.encode(state.toJson()));
      log('Saved PlayQueueState');
    } catch (e) {
      log('Error saving PlayQueueState: $e');
    }
  }
}

PlayQueueStore usePlayQueueStore() => create(() => PlayQueueStore());
