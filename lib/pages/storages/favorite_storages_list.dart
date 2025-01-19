import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/dialog/show_local_dialog.dart';
import 'package:iris/pages/dialog/show_webdav_dialog.dart';

class FavoriteStoragesList extends HookWidget {
  const FavoriteStoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final favoriteStorages =
        useStorageStore().select(context, (state) => state.favoriteStorages);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: favoriteStorages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(favoriteStorages[index].name),
        subtitle: () {
          switch (favoriteStorages[index].type) {
            case StorageType.local:
              return Text(
                favoriteStorages[index].basePath.join('/'),
                maxLines: 1,
                style: const TextStyle(overflow: TextOverflow.ellipsis),
              );
            case StorageType.webdav:
              return const Text('WebDAV');
          }
        }(),
        onTap: () {
          useStorageStore().updateCurrentPath(favoriteStorages[index].basePath);
          useStorageStore().updateCurrentStorage(favoriteStorages[index]);
        },
        trailing: PopupMenuButton<StorageOptions>(
          tooltip: t.menu,
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).colorScheme.surface.withAlpha(250),
          onSelected: (value) {
            switch (value) {
              case StorageOptions.edit:
                () {
                  switch (favoriteStorages[index].type) {
                    case StorageType.local:
                      showLocalDialog(
                        context,
                        storage: favoriteStorages[index] as LocalStorage,
                        isFavorite: true,
                      );
                      break;
                    case StorageType.webdav:
                      showWebDAVDialog(
                        context,
                        storage: favoriteStorages[index] as WebDAVStorage,
                        isFavorite: true,
                      );
                      break;
                  }
                }();
                break;
              case StorageOptions.remove:
                useStorageStore()
                    .removeFavoriteStorage(favoriteStorages[index]);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: StorageOptions.edit,
                child: Text(t.edit),
              ),
              PopupMenuItem(
                value: StorageOptions.remove,
                child: Text(t.remove),
              ),
            ];
          },
        ),
      ),
    );
  }
}
