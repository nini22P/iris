import 'dart:io';
import 'package:android_x_storage/android_x_storage.dart';
import 'package:disks_desktop/disks_desktop.dart';
import 'package:drives_windows/drives_windows.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/play_queue_state.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/files_sort.dart';
import 'package:iris/utils/get_subtitle_map.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/path_conv.dart';
import 'package:iris/utils/platform.dart';
import 'package:path/path.dart' as p;
import 'package:iris/models/file.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

Future<List<LocalStorage>> getLocalStorages(
  BuildContext context,
) async {
  final t = getLocalizations(context);
  if (isDesktop) {
    List<LocalStorage> storages = [];

    if (isWindows) {
      final drivesWindows = DrivesWindows();
      final drives = drivesWindows.getDrives();
      final networkShortcuts = drivesWindows.getNetworkShortcuts();

      for (var drive in drives) {
        if (drive.type == DriveType.noRootDirectory) continue;

        final type = drive.type == DriveType.network
            ? StorageType.network
            : StorageType.internal;
        final name = drive.volumeLabel != null
            ? '${drive.volumeLabel} (${drive.name})'
            : '${drive.type == DriveType.network ? t.network_storage : t.local_storage} (${drive.name})';
        final root = drive.root.replaceAll('\\', '');

        final storage = LocalStorage(
          type: type,
          name: name,
          basePath: [root],
        );

        storages.add(storage);
      }

      for (var shortcut in networkShortcuts) {
        if (shortcut.path == null) continue;
        final storage = LocalStorage(
          type: StorageType.network,
          name: shortcut.name,
          basePath: [shortcut.path!],
        );

        storages.add(storage);
      }
    } else {
      final repository = DisksRepository();
      final disks = await repository.query;
      List<LocalStorage> storages = [];

      for (var disk in disks) {
        for (var mountpoint in disk.mountpoints) {
          final storage = LocalStorage(
            type: StorageType.internal,
            name:
                '${t.local_storage} (${mountpoint.path.replaceAll('\\', '')})',
            basePath: [mountpoint.path.replaceAll('\\', '')],
          );

          storages.add(storage);
        }
      }
    }

    return storages;
  } else if (isAndroid) {
    final androidXStorage = AndroidXStorage();
    final external =
        await androidXStorage.getExternalStorageDirectory().catchError((error) {
      logger('Error getting external storage: $error');
      return null;
    });
    final sdcard =
        await androidXStorage.getSDCardStorageDirectory().catchError((error) {
      logger('Error getting SD card: $error');
      return null;
    });
    final usbs =
        await androidXStorage.getUSBStorageDirectories().catchError((error) {
      logger('Error getting USB storages: $error');
      return <String?>[];
    });

    List<LocalStorage> storages = [];

    if (external != null) {
      final storage = LocalStorage(
        type: StorageType.internal,
        name: t.local_storage,
        basePath: [external],
      );

      storages.add(storage);
    }

    if (sdcard != null) {
      final storage = LocalStorage(
        type: StorageType.sdcard,
        name: 'SD Card',
        basePath: [sdcard],
      );

      storages.add(storage);
    }

    for (var usb in usbs) {
      if (usb != null) {
        final storage = LocalStorage(
          type: StorageType.usb,
          name: t.usb_storage,
          basePath: [usb],
        );

        storages.add(storage);
      }
    }

    return storages;
  }
  return [];
}

Future<PlayQueueState?> getLocalPlayQueue(String filePath) async {
  final type = checkContentType(filePath);

  if (type != ContentType.video && type != ContentType.audio) {
    return null;
  }

  final convedPath = pathConv(filePath);

  final dirPath = convedPath.sublist(0, convedPath.length - 1);
  final files = await LocalStorage(
    type: StorageType.internal,
    name: convedPath.last,
    basePath: dirPath,
  ).getFiles(dirPath);
  final List<FileItem> sortedFiles = filesSort(files: files);
  final List<FileItem> filteredFiles = sortedFiles
      .where(
          (file) => [ContentType.video, ContentType.audio].contains(file.type))
      .toList();

  final List<PlayQueueItem> playQueue = filteredFiles
      .asMap()
      .entries
      .map((entry) => PlayQueueItem(file: entry.value, index: entry.key))
      .toList();

  final clickedFile = filteredFiles.where((file) => file.uri == filePath).first;

  final index = filteredFiles.indexOf(clickedFile);
  return PlayQueueState(
    playQueue: playQueue,
    currentIndex: index < 0 || index >= playQueue.length ? 0 : index,
  );
}

Future<void> pickLocalFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: [...Formats.video, ...Formats.audio],
  );

  final filePath = result?.files.first.path;

  if (filePath != null) {
    final playQueue = await getLocalPlayQueue(filePath);

    if (playQueue == null || playQueue.playQueue.isEmpty) return;

    await useAppStore().updateAutoPlay(true);
    await usePlayQueueStore().update(
      playQueue: playQueue.playQueue,
      index: playQueue.currentIndex,
    );
  }
}

Future<List<FileItem>> getLocalFiles(
    LocalStorage storage, List<String> path) async {
  final directoryPath = p.joinAll(path);
  final directory = Directory(directoryPath);

  if (!await directory.exists()) {
    logger('Error: Directory does not exist at $directoryPath');
    return [];
  }

  final Map<String, List<FileSystemEntity>> groupedEntities = {};
  final allEntities = await directory.list().toList();

  for (final entity in allEntities) {
    final baseName = p.basenameWithoutExtension(entity.path);
    groupedEntities.putIfAbsent(baseName, () => []).add(entity);
  }

  final List<FileItem> fileItems = [];
  final subtitleExtensions = {'ass', 'srt', 'vtt', 'sub'};

  for (final group in groupedEntities.values) {
    final videos = group
        .where((e) =>
            e is! Directory && checkContentType(e.path) == ContentType.video)
        .toList();
    final subtitles = group.where((e) {
      final ext = p.extension(e.path).replaceFirst('.', '');
      return e is! Directory && subtitleExtensions.contains(ext);
    }).toList();
    final others = group
        .where((e) => !videos.contains(e) && !subtitles.contains(e))
        .toList();

    for (final video in videos) {
      final videoStat = await video.stat();
      final associatedSubtitles = subtitles.map((sub) {
        final baseName = p.basenameWithoutExtension(video.path);
        String subTitleName = p.basename(sub.path);
        final regex = RegExp(r'^' + RegExp.escape(baseName) + r'\.(.+?)\.');
        final match = regex.firstMatch(subTitleName);
        if (match != null) {
          subTitleName = match.group(1) ?? subTitleName;
        }
        return Subtitle(name: subTitleName, uri: sub.path);
      }).toList();

      fileItems.add(FileItem(
        storageId: storage.id,
        storageType: storage.type,
        name: p.basename(video.path),
        uri: video.path,
        path: [...path, p.basename(video.path)],
        isDir: false,
        size: videoStat.size,
        lastModified: videoStat.modified,
        type: ContentType.video,
        subtitles: associatedSubtitles,
      ));
    }

    for (final entity in others) {
      final stat = await entity.stat();
      final isDir = entity is Directory;
      fileItems.add(FileItem(
        storageId: storage.id,
        storageType: storage.type,
        name: p.basename(entity.path),
        uri: entity.path,
        path: [...path, p.basename(entity.path)],
        isDir: isDir,
        size: isDir ? 0 : stat.size,
        lastModified: stat.modified,
        type: isDir ? ContentType.other : checkContentType(entity.path),
        subtitles: [],
      ));
    }
  }

  return fileItems;
}

Future<void> pickContentFile() async {
  final file = await SafUtil().pickFile(mimeTypes: ['video/*', 'audio/*']);
  if (file != null) {
    await useAppStore().updateAutoPlay(true);
    await usePlayQueueStore().update(
      playQueue: [
        PlayQueueItem(
          file: FileItem(
            name: file.name,
            uri: file.uri,
            size: file.length,
          ),
          index: 0,
        ),
      ],
      index: 0,
    );
  }
}

Future<List<FileItem>> getContentFiles(String uri) async {
  final files = await SafUtil().list(uri);

  final subtitleMap = getSubtitleMap<SafDocumentFile>(
    files: files,
    getName: (file) => file.name,
    getUri: (file) => file.uri,
  );

  List<FileItem> fileItems = [];

  for (final file in files) {
    final basename = p.basenameWithoutExtension(file.name).split('.').first;
    fileItems.add(FileItem(
      name: file.name,
      uri: file.uri,
      path: [uri, file.name],
      isDir: file.isDir,
      size: file.isDir ? 0 : file.length,
      lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
      type: file.isDir ? ContentType.other : checkContentType(file.name),
      subtitles: isVideoFile(file.name) ? subtitleMap[basename] ?? [] : [],
    ));
  }

  return fileItems;
}
