import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/ftp.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/webdav.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/popup.dart';
import 'package:iris/widgets/popups/storages/storages.dart';
import 'package:iris/store/use_storage_store.dart';

part 'storage.freezed.dart';
part 'storage.g.dart';

const String localStorageId = 'local';

enum StorageType {
  none,
  internal,
  network,
  usb,
  sdcard,
  webdav,
  ftp,
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

  String? getAuth();
}

@freezed
sealed class Storage with _$Storage implements _Storage {
  const Storage._();

  factory Storage.local({
    @Default(localStorageId) String id,
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

  factory Storage.ftp({
    required String id,
    @Default(StorageType.ftp) StorageType type,
    required String name,
    required String host,
    required List<String> basePath,
    required String port,
    required String username,
    required String password,
  }) = FTPStorage;

  factory Storage.fromJson(Map<String, dynamic> json) =>
      _$StorageFromJson(json);

  @override
  Future<List<FileItem>> getFiles(List<String> path) async {
    switch (type) {
      case StorageType.internal:
      case StorageType.network:
      case StorageType.usb:
      case StorageType.sdcard:
        if (isAndroid && path[0].startsWith('content://')) {
          return await getContentFiles(path.join('%2F'));
        } else {
          return await getLocalFiles(this as LocalStorage, path);
        }
      case StorageType.webdav:
        return await getWebDAVFiles(this as WebDAVStorage, path);
      case StorageType.ftp:
        return await getFTPFiles(this as FTPStorage, path);
      case StorageType.none:
        return [];
    }
  }

  @override
  String? getAuth() {
    switch (type) {
      case StorageType.webdav:
        return getWebDAVAuth(this as WebDAVStorage);
      case StorageType.ftp:
        return getFTPAuth(this as FTPStorage);
      default:
        return null;
    }
  }
}

Future<void> openInFolder(BuildContext context, FileItem file) async {
  if (file.path.isEmpty) return;
  useStorageStore()
      .updateCurrentPath(file.path.sublist(0, file.path.length - 1));

  Storage? storage = useStorageStore().findById(file.storageId);

  if (storage != null) {
    useStorageStore().updateCurrentStorage(storage);
  } else {
    final localStorages = await getLocalStorages(context);
    Storage? storage = localStorages
        .firstWhereOrNull((element) => element.basePath[0] == file.path[0]);
    if (storage != null) {
      useStorageStore().updateCurrentStorage(storage);
    } else {
      useStorageStore().updateCurrentStorage(
        LocalStorage(
          type: file.storageType,
          name: file.path[0],
          basePath: [file.path[0]],
        ),
      );
    }
  }

  if (context.mounted) {
    replacePopup(
      context: context,
      child: Storages(),
      direction: PopupDirection.right,
    );
  }
}
