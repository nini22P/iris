import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/dialog/show_local_dialog.dart';
import 'package:iris/pages/dialog/show_webdav_dialog.dart';

class StoragesList extends HookWidget {
  const StoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final storages =
        useStorageStore().select(context, (state) => state.storages);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: storages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(storages[index].name),
        subtitle: () {
          switch (storages[index].type) {
            case StorageType.local:
              return Text(storages[index].basePath.join('/'));
            case StorageType.webdav:
              return const Text('WebDAV');
          }
        }(),
        onTap: () {
          useStorageStore().updateCurrentPath(storages[index].basePath);
          useStorageStore().updateCurrentStorage(storages[index]);
        },
        trailing: PopupMenuButton<StorageOptions>(
          tooltip: t.menu,
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).colorScheme.surface.withAlpha(250),
          onSelected: (value) {
            switch (value) {
              case StorageOptions.edit:
                () {
                  switch (storages[index].type) {
                    case StorageType.local:
                      showLocalDialog(context,
                          storage: storages[index] as LocalStorage);
                      break;
                    case StorageType.webdav:
                      showWebDAVDialog(context,
                          storage: storages[index] as WebDAVStorage);
                      break;
                  }
                }();
                break;
              case StorageOptions.remove:
                useStorageStore().removeStorage(storages[index]);
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
