import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/file_filter.dart';
import 'package:iris/utils/file_sort.dart';
import 'package:iris/utils/find_sub_title.dart';
import 'package:iris/utils/path_converter.dart';
import 'package:path/path.dart' as p;
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/utils/check_file_type.dart';

class LocalStorage implements Storage {
  @override
  String id = 'local';
  @override
  String type = 'local';
  @override
  String name;
  @override
  List<String> basePath;

  LocalStorage({
    required this.id,
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
        id: id,
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
      'id': id,
      'type': type,
      'name': name,
      'basePath': basePath,
    };
  }

  factory LocalStorage.fromJson(Map<String, dynamic> json) {
    return LocalStorage(
        id: json['id'] ?? 'local',
        type: json['type'],
        name: json['name'],
        basePath: List<String>.from(json['basePath']));
  }
}

Future<void> pickFile() async {
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: Formats.video);

  if (result != null) {
    final filePath = pathConverter(result.files.first.path!);
    final basePath = filePath.sublist(0, filePath.length - 1);
    final files = await LocalStorage(
      id: 'local',
      type: 'local',
      name: result.files.first.name,
      basePath: basePath,
    ).getFiles(basePath);

    final playQueue = fileFilter(files, 'video');
    final clickedFile = playQueue
        .where((file) => file.uri == filePath.join('/').toString())
        .first;
    final index = playQueue.indexOf(clickedFile);

    if (playQueue.isEmpty || index < 0) return;

    await useAppStore().updateAutoPlay(true);
    await usePlayQueueStore().updatePlayQueue(playQueue, index);
  }
}
