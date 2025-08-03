import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/models/store/storage_state.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';

class FileButtons extends HookWidget {
  const FileButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final refreshState = useState(false);
    void refresh() => refreshState.value = !refreshState.value;

    final sortBy = useAppStore().select(context, (state) => state.sortBy);
    final sortOrder = useAppStore().select(context, (state) => state.sortOrder);
    final folderFirst =
        useAppStore().select(context, (state) => state.folderFirst);

    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    final favorites =
        useStorageStore().select(context, (state) => state.favorites);
    final currentPath =
        useStorageStore().select(context, (state) => state.currentPath);

    final currentFavorite = useMemoized(
        () => favorites.firstWhereOrNull((favorite) =>
            favorite.storageId == currentStorage?.id &&
            favorite.path == currentPath),
        [favorites, currentPath]);

    useEffect(() {
      if (currentPath.isEmpty) {
        final basePath = currentStorage?.basePath;
        if (basePath != null) {
          useStorageStore().updateCurrentPath(basePath);
        }
      }
      return null;
    }, []);

    void back() {
      final basePath = currentStorage?.basePath;
      if (basePath == null) return;
      if (currentPath.length > basePath.length) {
        useStorageStore()
            .updateCurrentPath(currentPath.sublist(0, currentPath.length - 1));
      } else {
        useStorageStore().updateCurrentStorage(null);
        useStorageStore().updateCurrentPath([]);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: back,
        ),
        IconButton(
          tooltip: t.home,
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            useStorageStore().updateCurrentStorage(null);
            useStorageStore().updateCurrentPath([]);
          },
        ),
        IconButton(
          tooltip: t.refresh,
          icon: const Icon(Icons.refresh),
          onPressed: refresh,
        ),
        PopupMenuButton(
          tooltip: t.sort,
          icon: const Icon(Icons.sort_rounded),
          clipBehavior: Clip.hardEdge,
          constraints: const BoxConstraints(minWidth: 200),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                mouseCursor: SystemMouseCursors.click,
                title: Text(t.name),
                trailing: sortBy == SortBy.name
                    ? Icon(sortOrder == SortOrder.asc
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : null,
              ),
              onTap: () {
                useAppStore().updateSortBy(SortBy.name);
                useAppStore().updateSortOrder(
                    sortOrder == SortOrder.desc || sortBy != SortBy.name
                        ? SortOrder.asc
                        : SortOrder.desc);
              },
            ),
            PopupMenuItem(
              child: ListTile(
                mouseCursor: SystemMouseCursors.click,
                title: Text(t.size),
                trailing: sortBy == SortBy.size
                    ? Icon(sortOrder == SortOrder.asc
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : null,
              ),
              onTap: () {
                useAppStore().updateSortBy(SortBy.size);
                useAppStore().updateSortOrder(
                    sortOrder == SortOrder.asc || sortBy != SortBy.size
                        ? SortOrder.desc
                        : SortOrder.asc);
              },
            ),
            PopupMenuItem(
              child: ListTile(
                mouseCursor: SystemMouseCursors.click,
                title: Text(t.last_modified),
                trailing: sortBy == SortBy.lastModified
                    ? Icon(sortOrder == SortOrder.asc
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : null,
              ),
              onTap: () {
                useAppStore().updateSortBy(SortBy.lastModified);
                useAppStore().updateSortOrder(
                    sortOrder == SortOrder.asc || sortBy != SortBy.lastModified
                        ? SortOrder.desc
                        : SortOrder.asc);
              },
            ),
            PopupMenuItem(
              child: ListTile(
                mouseCursor: SystemMouseCursors.click,
                title: Text(t.folder_first),
                trailing: Checkbox(
                    value: folderFirst,
                    onChanged: (_) {
                      useAppStore().updateFolderFirst(!folderFirst);
                      Navigator.pop(context);
                    }),
              ),
              onTap: () => useAppStore().updateFolderFirst(!folderFirst),
            ),
          ],
        ),
        IconButton(
          tooltip: currentFavorite != null ? t.remove_favorite : t.add_favorite,
          icon: Icon(currentFavorite != null
              ? Icons.star_rounded
              : Icons.star_outline_rounded),
          onPressed: () {
            if (currentFavorite != null) {
              useStorageStore().removeFavorite(currentFavorite);
            } else {
              final storageId = currentStorage?.id;
              if (storageId == null) return;
              useStorageStore().addFavorite(
                Favorite(storageId: storageId, path: currentPath),
              );
            }
          },
        ),
        // const SizedBox(width: 8),
        // Expanded(
        //   child: Text(
        //     currentPath.length > 1
        //         ? currentPath.last
        //         : currentStorage!.basePath.length > 1
        //             ? currentPath.first
        //             : currentStorage.name,
        //     maxLines: 1,
        //     style: const TextStyle(
        //       fontWeight: FontWeight.w500,
        //       overflow: TextOverflow.ellipsis,
        //     ),
        //   ),
        // ),
        // IconButton(
        //   tooltip: '${t.close} ( Escape )',
        //   icon: const Icon(Icons.close_rounded),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ],
    );
  }
}
