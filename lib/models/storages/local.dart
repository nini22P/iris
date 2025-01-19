import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/files_filter.dart';
import 'package:iris/utils/files_sort.dart';
import 'package:iris/utils/find_subtitle.dart';
import 'package:iris/utils/path_converter.dart';
import 'package:path/path.dart' as p;
import 'package:iris/models/file.dart';
import 'package:iris/utils/check_content_type.dart';

Future<void> pickLocalFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [...Formats.video, ...Formats.audio]);

  if (result != null) {
    final filePath = pathConverter(result.files.first.path!);
    final basePath = filePath.sublist(0, filePath.length - 1);
    final files = await LocalStorage(
      id: 'local',
      type: StorageType.local,
      name: result.files.first.name,
      basePath: basePath,
    ).getFiles(basePath);

    final List<FileItem> filteredFiles =
        filesFilter(files, [ContentType.video, ContentType.audio]);
    final List<PlayQueueItem> playQueue = filteredFiles
        .asMap()
        .entries
        .map((entry) => PlayQueueItem(file: entry.value, index: entry.key))
        .toList();

    final clickedFile = filteredFiles
        .where((file) => file.path.join('/') == filePath.join('/'))
        .first;
    final index = filteredFiles.indexOf(clickedFile);

    if (playQueue.isEmpty || index < 0) return;

    await useAppStore().updateAutoPlay(true);
    await usePlayQueueStore().updatePlayQueue(playQueue, index);
  }
}

Future<List<FileItem>> getLocalFiles(
    LocalStorage storage, List<String> path) async {
  final directory = Directory(path.join('/'));

  List<FileItem> files = [];
  try {
    final entities = directory.list();

    await for (final entity in entities) {
      final isDir = entity is Directory;
      int size = 0;
      if (!isDir) {
        final file = File(entity.path);
        size = await file.length();
      }

      final subtitles = await findLocalSubtitle(
        directory,
        p.basename(entity.path),
        entity.path,
      );

      files.add(FileItem(
          storageId: storage.id,
          storageType: storage.type,
          name: p.basename(entity.path),
          uri: pathConverter(entity.path).join('/'),
          path: [...path, p.basename(entity.path)],
          isDir: isDir,
          size: size,
          type: isDir
              ? ContentType.dir
              : checkContentType(p.basename(entity.path)),
          subtitles: subtitles));
    }
  } catch (e) {
    log('Error reading directory $path : $e');
    return [];
  }

  return filesSort(files, true);
}
