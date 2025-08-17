import 'dart:io';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/globals.dart' as globals;
import 'package:iris/models/file.dart';
import 'package:iris/models/progress.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_history_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/files_filter.dart';
import 'package:iris/utils/file_size_convert.dart';
import 'package:iris/utils/files_sort.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/utils/request_storage_permission.dart';
import 'package:iris/widgets/chip.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:permission_handler/permission_handler.dart';

class Files extends HookWidget {
  const Files({super.key, required this.storage});

  final Storage storage;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final safeAreaPadding = MediaQuery.of(context).padding;

    final refreshState = useState(false);
    void refresh() => refreshState.value = !refreshState.value;

    final sortBy = useAppStore().select(context, (state) => state.sortBy);
    final sortOrder = useAppStore().select(context, (state) => state.sortOrder);
    final folderFirst =
        useAppStore().select(context, (state) => state.folderFirst);

    final currentPath =
        useStorageStore().select(context, (state) => state.currentPath);

    useEffect(() {
      if (currentPath.isEmpty) {
        useStorageStore().updateCurrentPath(storage.basePath);
      }
      return null;
    }, []);

    final getFiles = useMemoized(
        () async => await storage.getFiles(currentPath),
        [currentPath, refreshState.value]);

    final result = useFuture(getFiles);
    final isLoading = useMemoized(
        () => result.connectionState == ConnectionState.waiting,
        [result.connectionState]);
    final isError = result.error != null;

    final filteredFiles = useMemoized(
        () => filesFilter(result.data ?? [],
            [ContentType.dir, ContentType.video, ContentType.audio]),
        [result.data]);

    final files = useMemoized(
        () => filesSort(
              files: filteredFiles,
              sortBy: sortBy,
              sortOrder: sortOrder,
              folderFirst: folderFirst,
            ),
        [filteredFiles, sortBy, sortOrder, folderFirst]);

    ItemScrollController itemScrollController = ItemScrollController();
    ScrollOffsetController scrollOffsetController = ScrollOffsetController();
    ItemPositionsListener itemPositionsListener =
        ItemPositionsListener.create();
    ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();

    void play(List<FileItem> files, int index) async {
      final clickedFile = files[index];
      final List<FileItem> filteredFiles =
          filesFilter(files, [ContentType.video, ContentType.audio]);
      final List<PlayQueueItem> playQueue = filteredFiles
          .asMap()
          .entries
          .map((entry) => PlayQueueItem(file: entry.value, index: entry.key))
          .toList();
      final newIndex = filteredFiles.indexOf(clickedFile);

      await useAppStore().updateAutoPlay(true);
      await useAppStore().updateShuffle(false);
      await usePlayQueueStore().update(playQueue: playQueue, index: newIndex);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isDesktop ? 56 : safeAreaPadding.top + 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: BreadCrumb.builder(
            itemCount: currentPath.length,
            overflow: Platform.isAndroid || Platform.isIOS
                ? ScrollableOverflow(reverse: true)
                : const WrapOverflow(),
            builder: (index) {
              return BreadCrumbItem(
                content: TextButton(
                  child: Text([
                    storage.basePath.length > 1
                        ? currentPath.first
                        : storage.name,
                    ...currentPath.sublist(1),
                  ][index]),
                  onPressed: () {
                    useStorageStore()
                        .updateCurrentPath(currentPath.sublist(0, index + 1));
                  },
                ),
              );
            },
            divider: Icon(
              Icons.chevron_right_rounded,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(222),
            ),
          ),
        ),
        Expanded(
          child: Platform.isAndroid &&
                  globals.storagePermissionStatus != PermissionStatus.granted &&
                  storage is LocalStorage
              ? Center(
                  child: ElevatedButton(
                      onPressed: () async {
                        await requestStoragePermission();
                        refresh();
                      },
                      child: Text(t.grant_storage_permission)),
                )
              : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isError
                      ? Center(child: Text(t.unable_to_fetch_files))
                      : files.isEmpty
                          ? const Center()
                          : ScrollablePositionedList.builder(
                              padding: EdgeInsets.only(
                                  top: 8,
                                  bottom: isDesktop
                                      ? 106
                                      : safeAreaPadding.bottom + 168),
                              itemScrollController: itemScrollController,
                              scrollOffsetController: scrollOffsetController,
                              itemPositionsListener: itemPositionsListener,
                              scrollOffsetListener: scrollOffsetListener,
                              itemCount: files.length,
                              itemBuilder: (context, index) => ListTile(
                                contentPadding:
                                    const EdgeInsets.fromLTRB(16, 0, 8, 0),
                                visualDensity: const VisualDensity(
                                    horizontal: 0, vertical: -4),
                                leading: () {
                                  switch (files[index].type) {
                                    case ContentType.dir:
                                      return const Icon(Icons.folder_rounded);
                                    case ContentType.video:
                                      return const Icon(Icons.movie_rounded);
                                    case ContentType.audio:
                                      return const Icon(
                                          Icons.audiotrack_rounded);
                                    case ContentType.image:
                                      return const Icon(Icons.image_rounded);
                                    case ContentType.other:
                                      return const Icon(
                                          Icons.file_copy_rounded);
                                  }
                                }(),
                                title: Text(
                                  files[index].name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textBaseline: TextBaseline.ideographic,
                                  children: [
                                    if (files[index].size != 0)
                                      Text(
                                        "${fileSizeConvert(files[index].size)} MB",
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    if (files[index].size != 0)
                                      const SizedBox(width: 8),
                                    if (files[index].lastModified != null)
                                      Expanded(
                                        child: Text(
                                          files[index]
                                              .lastModified
                                              .toString()
                                              .split('.')[0],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w400,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    if (files[index].size != 0)
                                      const SizedBox(width: 8),
                                    () {
                                      final Progress? progress =
                                          useHistoryStore()
                                              .findById(files[index].getID());
                                      if (progress != null &&
                                          progress.file.type ==
                                              ContentType.video) {
                                        if ((progress.duration.inMilliseconds -
                                                progress
                                                    .position.inMilliseconds) <=
                                            5000) {
                                          return Chip(text: '100%');
                                        }
                                        final String progressString =
                                            (progress.position.inMilliseconds /
                                                    progress.duration
                                                        .inMilliseconds *
                                                    100)
                                                .toStringAsFixed(0);
                                        return Chip(text: '$progressString %');
                                      } else {
                                        return const SizedBox();
                                      }
                                    }(),
                                    ...files[index]
                                        .subtitles
                                        .map((subtitle) => subtitle.uri
                                            .split('.')
                                            .last
                                            .toUpperCase())
                                        .toSet()
                                        .toList()
                                        .map(
                                          (subtitleType) => Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(width: 4),
                                              Chip(
                                                text: subtitleType,
                                                primary: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                  ],
                                ),
                                trailing: files[index].type ==
                                            ContentType.video ||
                                        files[index].type == ContentType.audio
                                    ? PopupMenuButton<FileOptions>(
                                        clipBehavior: Clip.hardEdge,
                                        constraints:
                                            const BoxConstraints(minWidth: 200),
                                        onSelected: (value) async {
                                          switch (value) {
                                            case FileOptions.addToPlayQueue:
                                              usePlayQueueStore()
                                                  .add([files[index]]);
                                              break;
                                            default:
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: FileOptions.addToPlayQueue,
                                            child: Text(t.add_to_play_queue),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  if (files[index].isDir == true &&
                                      files[index].name.isNotEmpty) {
                                    useStorageStore().updateCurrentPath(
                                        [...currentPath, files[index].name]);
                                  } else {
                                    if (files[index].type ==
                                            ContentType.video ||
                                        files[index].type ==
                                            ContentType.audio) {
                                      play(files, index);
                                      if (files[index].type ==
                                          ContentType.video) {
                                        useUiStore().updatePlayerExpanded(true);
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
        ),
      ],
    );
  }
}
