import 'package:iris/models/file.dart';

enum StorageType {
  local,
  webdav,
}

extension StorageTypeExtension on StorageType {
  String get name {
    switch (this) {
      case StorageType.local:
        return 'local';
      case StorageType.webdav:
        return 'webdav';
    }
  }

  static StorageType fromString(String type) {
    switch (type) {
      case 'local':
        return StorageType.local;
      case 'webdav':
        return StorageType.webdav;
      default:
        throw Exception('Unknown storage type: $type');
    }
  }
}

abstract class Storage {
  String get id;
  StorageType get type;
  String get name;
  List<String> get basePath;

  Map<String, dynamic> toJson();

  Future<List<FileItem>> getFiles(List<String> path);
}
