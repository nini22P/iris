import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:iris/models/storages/storage.dart';

part 'storage_state.freezed.dart';
part 'storage_state.g.dart';

@freezed
class StorageState with _$StorageState {
  factory StorageState({
    @Default([]) List<Storage> storages,
    @Default([]) List<Storage> favoriteStorages,
    @Default(null) Storage? currentStorage,
    @Default([]) List<String> currentPath,
  }) = _StorageState;

  factory StorageState.fromJson(Map<String, dynamic> json) =>
      _$StorageStateFromJson(json);
}
