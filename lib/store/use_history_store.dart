import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/progress.dart';
import 'package:iris/models/store/history_state.dart';
import 'package:iris/store/persistent_store.dart';
import 'package:iris/utils/logger.dart';

class HistoryStore extends PersistentStore<HistoryState> {
  HistoryStore() : super(HistoryState());

  Progress? findById(String id) => state.history[id];

  Future<void> add(Progress progress) async {
    set(state.copyWith(
      history: {
        ...state.history,
        progress.file.getID(): progress,
      },
    ));
    await save(state);
  }

  Future<void> remove(Progress progress) async {
    set(state.copyWith(
        history: {...state.history}..remove(progress.file.getID())));
    await save(state);
  }

  Future<void> clear() async {
    set(state.copyWith(history: {}));
    await save(state);
  }

  @override
  Future<HistoryState?> load() async {
    logger('Loading HistoryState');
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      String? historyState = await storage.read(key: 'history_state');
      if (historyState != null) {
        return HistoryState.fromJson(json.decode(historyState));
      }
    } catch (e) {
      logger('Error loading HistoryState: $e');
    }
    return null;
  }

  @override
  Future<void> save(HistoryState state) async {
    try {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());

      await storage.write(
          key: 'history_state', value: json.encode(state.toJson()));
    } catch (e) {
      logger('Error saving HistoryState: $e');
    }
  }
}

HistoryStore useHistoryStore() => create(() => HistoryStore());
