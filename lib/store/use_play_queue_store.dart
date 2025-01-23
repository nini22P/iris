import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/store/play_queue_state.dart';
import 'package:iris/store/persistent_store.dart';
import 'package:iris/globals.dart' as globals;
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/decode_uri.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/utils/path_conv.dart';

class PlayQueueStore extends PersistentStore<PlayQueueState> {
  PlayQueueStore() : super(PlayQueueState());

  Future<void> update({
    required List<PlayQueueItem> playQueue,
    int? index,
  }) async {
    set(state.copyWith(
      playQueue: playQueue,
      currentIndex: index ?? state.currentIndex,
    ));
    if (Platform.isAndroid &&
        state.playQueue.any((e) => e.file.uri.startsWith('content://'))) {
      return;
    }
    await save(state);
  }

  Future<void> updateCurrentIndex(int index) async {
    set(state.copyWith(currentIndex: index));
    if (Platform.isAndroid &&
        state.playQueue.any((e) => e.file.uri.startsWith('content://'))) {
      return;
    }
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
    if (Platform.isAndroid &&
        state.playQueue.any((e) => e.file.uri.startsWith('content://'))) {
      return;
    }
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
    if (Platform.isAndroid &&
        state.playQueue.any((e) => e.file.uri.startsWith('content://'))) {
      return;
    }
    await save(state);
  }

  @override
  Future<PlayQueueState?> load() async {
    log('Loading PlayQueueState');
    try {
      if (isDesktop && globals.arguments.isNotEmpty) {
        String uri = globals.arguments[0];
        // 在线播放
        if (RegExp(r'^(http://|https://)').hasMatch(uri)) {
          final state = PlayQueueState(
            playQueue: [
              PlayQueueItem(
                file: FileItem(
                  name: uri,
                  uri: uri,
                ),
                index: 0,
              )
            ],
            currentIndex: 0,
          );
          save(state);
          return state;
        }

        // 本地播放
        final filePath = pathConv(uri);
        final state = await getLocalPlayQueue(filePath);
        if (state != null && state.playQueue.isNotEmpty) {
          save(state);
          return state;
        }
      }

      final uri = globals.initUri;

      // Android
      if (uri != null && Platform.isAndroid) {
        final decodedPath = decodePath(uri.path);
        final fileName = Uri.decodeComponent(decodedPath.last);
        await useAppStore().updateAutoPlay(true);
        return PlayQueueState(
          playQueue: [
            PlayQueueItem(
              file: FileItem(
                name: fileName,
                uri: uri.toString(),
              ),
              index: 0,
            ),
          ],
          currentIndex: 0,
        );
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
