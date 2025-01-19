import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/webdav.dart';

part 'storage.freezed.dart';
part 'storage.g.dart';

enum StorageType {
  local,
  webdav,
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
