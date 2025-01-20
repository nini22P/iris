import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';

class Favorites extends HookWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final favorites =
        useStorageStore().select(context, (state) => state.favorites);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: favorites.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(favorites[index].path.last),
        subtitle: () {
          final storage =
              useStorageStore().findById(favorites[index].storageId);
          if (storage == null) return null;
          if (storage is LocalStorage) {
            return Text(
              favorites[index].path.join('/'),
              maxLines: 1,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            );
          } else if (storage is WebDAVStorage) {
            return Text(
                'http${storage.https ? 's' : ''}://${storage.url}${favorites[index].path.join('/')}');
          }
        }(),
        onTap: () {
          final storage =
              useStorageStore().findById(favorites[index].storageId);
          if (storage == null) return;
          useStorageStore().updateCurrentPath(favorites[index].path);
          useStorageStore().updateCurrentStorage(storage);
        },
        trailing: PopupMenuButton<StorageOptions>(
          tooltip: t.menu,
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).colorScheme.surface.withAlpha(250),
          onSelected: (value) {
            switch (value) {
              case StorageOptions.remove:
                useStorageStore().removeFavorite(favorites[index]);
                break;
              default:
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // PopupMenuItem(
              //   value: StorageOptions.edit,
              //   child: Text(t.edit),
              // ),
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
