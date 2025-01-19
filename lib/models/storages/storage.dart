import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/webdav.dart';
import 'package:iris/pages/popup/show_popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:iris/store/use_storage_store.dart';

part 'storage.freezed.dart';
part 'storage.g.dart';

enum StorageType {
  local,
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
    required String id,
    @Default(StorageType.local) StorageType type,
    required String name,
    required List<String> basePath,
  }) = LocalStorage;

  factory Storage.webdav({
    required String id,
    @Default(StorageType.webdav) StorageType type,
    required String name,
    required String url,
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
      case StorageType.local:
        return await getLocalFiles(this as LocalStorage, path);
      case StorageType.webdav:
        return await getWebDAVFiles(this as WebDAVStorage, path);
    }
  }
}

Future<void> openInFolder(BuildContext context, FileItem file) async {
  Storage? storage = await useStorageStore().getStorageById(file.storageId);
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
  } else if (file.storageType == StorageType.local) {
    useStorageStore()
        .updateCurrentPath(file.path.sublist(0, file.path.length - 1));
    useStorageStore().updateCurrentStorage(LocalStorage(
        id: 'local', name: file.path[0], basePath: [file.path[0]]));
    if (context.mounted) {
      replacePopup(
        context: context,
        child: Storages(),
        direction: PopupDirection.right,
      );
    }
  }
}
