import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/webdav.dart';
import 'package:iris/widgets/popup.dart';
import 'package:iris/pages/storage/storages.dart';
import 'package:iris/store/use_storage_store.dart';

part 'storage.freezed.dart';
part 'storage.g.dart';

enum StorageType {
  none,
  internal,
  usb,
  sdcard,
  webdav,
}

enum StorageOptions {
  edit,
  remove,
}

abstract class _Storage {
  String get id;
  StorageType get type;
  String get name;
  List<String> get basePath;

  Map<String, dynamic> toJson();

  Future<List<FileItem>> getFiles(List<String> path);
}

@freezed
sealed class Storage with _$Storage implements _Storage {
  const Storage._();

  factory Storage.local({
    @Default('local') String id,
    required StorageType type,
    required String name,
    required List<String> basePath,
  }) = LocalStorage;

  factory Storage.webdav({
    required String id,
    @Default(StorageType.webdav) StorageType type,
    required String name,
    @JsonKey(name: 'url') required String host,
    required List<String> basePath,
    required String port,
    required String username,
    required String password,
    required bool https,
  }) = WebDAVStorage;

  factory Storage.fromJson(Map<String, dynamic> json) =>
      _$StorageFromJson(json);

  @override
  Future<List<FileItem>> getFiles(List<String> path) async {
    switch (type) {
      case StorageType.internal:
      case StorageType.usb:
      case StorageType.sdcard:
        return await getLocalFiles(this as LocalStorage, path);
      case StorageType.webdav:
        return await getWebDAVFiles(this as WebDAVStorage, path);
      default:
        return [];
    }
  }
}

Future<void> openInFolder(BuildContext context, FileItem file) async {
  if (file.path.isEmpty) return;
  Storage? storage = useStorageStore().findById(file.storageId);
  if (storage != null) {
    useStorageStore()
        .updateCurrentPath(file.path.sublist(0, file.path.length - 1));
    useStorageStore().updateCurrentStorage(storage);
    if (context.mounted) {
      replacePopup(
        context: context,
        child: Storages(),
        direction: PopupDirection.right,
      );
    }
  } else if (file.storageType == StorageType.internal ||
      file.storageType == StorageType.usb ||
      file.storageType == StorageType.sdcard) {
    useStorageStore()
        .updateCurrentPath(file.path.sublist(0, file.path.length - 1));
    useStorageStore().updateCurrentStorage(
      LocalStorage(
        type: file.storageType,
        name: file.path[0],
        basePath: [file.path[0]],
      ),
    );
    if (context.mounted) {
      replacePopup(
        context: context,
        child: Storages(),
        direction: PopupDirection.right,
      );
    }
  }
}
