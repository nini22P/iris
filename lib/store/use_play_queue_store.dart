import 'dart:convert';
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/store/play_queue_state.dart';
import 'package:iris/store/persistent_store.dart';
import 'package:iris/globals.dart' as globals;
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/path_converter.dart';

class PlayQueueStore extends PersistentStore<PlayQueueState> {
  PlayQueueStore() : super(PlayQueueState());

  Future<void> update(List<PlayQueueItem> playQueue, int? index) async {
    set(state.copyWith(
      playQueue: playQueue,
      currentIndex: index ?? state.currentIndex,
    ));
    await save(state);
  }

  Future<void> updateCurrentIndex(int index) async {
    set(state.copyWith(currentIndex: index));
    await save(state);
  }

  Future<void> add(List<FileItem> files) async {
    final int startIndex = state.playQueue.isEmpty
        ? 0
        : state.playQueue
                .sorted((a, b) => a.index.compareTo(b.index))
                .last
                .index +
            1;

    final List<PlayQueueItem> playQueue = files
        .asMap()
        .entries
        .map((entry) =>
            PlayQueueItem(file: entry.value, index: startIndex + entry.key))
        .toList();

    set(state.copyWith(playQueue: [...state.playQueue, ...playQueue]));
    await save(state);
  }

  Future<void> remove(PlayQueueItem item) async {
    if (state.playQueue.length <= 1) {
      set(state.copyWith(playQueue: [], currentIndex: 0));
    } else {
      final index = state.playQueue.indexOf(item);
      if (state.playQueue[index].index == state.currentIndex) {
        if (index + 1 < state.playQueue.length) {
          set(state.copyWith(
            playQueue: [...state.playQueue]..remove(item),
            currentIndex: state.playQueue[index + 1].index,
          ));
        } else {
          set(state.copyWith(
            playQueue: [...state.playQueue]..remove(item),
            currentIndex: state.playQueue[index - 1].index,
          ));
        }
      } else {
        set(state.copyWith(
          playQueue: [...state.playQueue]..remove(item),
        ));
      }
    }
    await save(state);
  }

  @override
  Future<PlayQueueState?> load() async {
    try {
      if (globals.arguments.isNotEmpty && globals.arguments[0].isNotEmpty) {
        final filePath = pathConverter(globals.arguments[0]);
        if (checkContentType(filePath.last) == ContentType.video ||
            checkContentType(filePath.last) == ContentType.audio) {
          final state = await getLocalPlayQueue(filePath);
          if (state != null && state.playQueue.isNotEmpty) {
            save(state);
            return state;
          }
        }
      }

      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? appState = await storage.read(key: 'playQueue_state');
      if (appState != null) {
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
          key: 'playQueue_state', value: json.encode(state.toJson()));
    } catch (e) {
      log('Error saving PlayQueueState: $e');
    }
  }
}

PlayQueueStore usePlayQueueStore() => create(() => PlayQueueStore());
