import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:path/path.dart' as p;

class Favorites extends HookWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final favorites =
        useStorageStore().select(context, (state) => state.favorites);

    final localStoragesFuture =
        useMemoized(() async => await getLocalStorages(context), []);
    final localStorages = useFuture(localStoragesFuture).data ?? [];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: favorites.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(favorites[index].path.last),
        subtitle: () {
          Storage? storage =
              useStorageStore().findById(favorites[index].storageId);
          if (storage == null && favorites[index].storageId == localStorageId) {
            storage = localStorages.firstWhereOrNull(
                (element) => element.basePath[0] == favorites[index].path[0]);
          }
          if (storage == null) return null;
          if (storage is LocalStorage) {
            final subtitle = p.normalize(favorites[index].path.join('/'));
            if (favorites[index].path.last == subtitle) {
              return null;
            }
            return Text(
              subtitle,
              maxLines: 1,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            );
          } else if (storage is WebDAVStorage) {
            return Text(
                'http${storage.https ? 's' : ''}://${storage.host}${storage.port.isNotEmpty && storage.port != '80' && storage.port != '443' ? ':${storage.port}' : ''}${favorites[index].path.join('/')}');
          } else if (storage is FTPStorage) {
            return Text(
                'ftp://${storage.username.isNotEmpty ? '${storage.username}@' : ''}${storage.host}:${storage.port}${favorites[index].path.join('/').replaceFirst('//', '/')}');
          } else {
            return null;
          }
        }(),
        onTap: () {
          Storage? storage =
              useStorageStore().findById(favorites[index].storageId);
          if (storage == null && favorites[index].storageId == localStorageId) {
            storage = localStorages.firstWhereOrNull(
                (element) => element.basePath[0] == favorites[index].path[0]);
          }
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
