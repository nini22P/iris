import 'dart:io';
import 'package:iris/utils/file_sort.dart';
import 'package:iris/utils/find_sub_title.dart';
import 'package:iris/utils/path_converter.dart';
import 'package:path/path.dart' as p;
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/utils/check_file_type.dart';

class LocalStorage implements Storage {
  @override
  String type = 'local';
  @override
  String name;
  @override
  List<String> basePath;

  LocalStorage({
    required this.type,
    required this.name,
    required this.basePath,
  });

  @override
  LocalStorage copyWith({
    String? name,
    List<String>? basePath,
  }) =>
      LocalStorage(
        type: type,
        name: name ?? this.name,
        basePath: basePath ?? this.basePath,
      );

  @override
  Future<List<FileItem>> getFiles(List<String> path) async {
    final directory = Directory(path.join('/'));
    final files = directory
        .listSync()
        .map((entity) => FileItem(
              name: p.basename(entity.path),
              uri: pathConverter(entity.path).join('/'),
              path: path,
              isDir: entity is Directory,
              size: entity is File ? entity.lengthSync() : 0,
              type: checkFileType(p.basename(entity.path)),
              subtitles: findSubTitle(
                  directory
                      .listSync()
                      .map((entity) => p.basename(entity.path))
                      .toList(),
                  p.basename(entity.path),
                  entity.path),
            ))
        .toList();
    return fileSort(files, true);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'basePath': basePath,
    };
  }

  factory LocalStorage.fromJson(Map<String, dynamic> json) {
    return LocalStorage(
        type: json['type'],
        name: json['name'],
        basePath: List<String>.from(json['basePath']));
  }
}
