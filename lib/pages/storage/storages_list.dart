import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/pages/dialog/show_local_dialog.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/dialog/show_webdav_dialog.dart';
import 'package:iris/utils/is_desktop.dart';

class StoragesList extends HookWidget {
  const StoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final localStorages =
        useStorageStore().select(context, (state) => state.localStorages);
    final storages =
        useStorageStore().select(context, (state) => state.storages);

    final allStorages = useMemoized(
        () => [
              ...localStorages,
              ...storages,
            ],
        [localStorages, storages]);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: allStorages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(allStorages[index].name),
        subtitle: localStorages.contains(allStorages[index]) && isDesktop
            ? null
            : () {
                switch (allStorages[index].type) {
                  case StorageType.internal:
                  case StorageType.usb:
                  case StorageType.sdcard:
                    return Text(allStorages[index].basePath.join('/'));
                  case StorageType.webdav:
                    final storage = allStorages[index] as WebDAVStorage;
                    return Text(
                        'http${storage.https ? 's' : ''}://${storage.host}${storage.basePath.join('/')}');
                  default:
                    return null;
                }
              }(),
        onTap: () {
          useStorageStore().updateCurrentPath(allStorages[index].basePath);
          useStorageStore().updateCurrentStorage(allStorages[index]);
        },
        trailing: localStorages.contains(allStorages[index])
            ? null
            : PopupMenuButton<StorageOptions>(
                tooltip: t.menu,
                clipBehavior: Clip.hardEdge,
                color: Theme.of(context).colorScheme.surface.withAlpha(250),
                onSelected: (value) {
                  switch (value) {
                    case StorageOptions.edit:
                      if (allStorages[index] is WebDAVStorage) {
                        showWebDAVDialog(context,
                            storage: allStorages[index] as WebDAVStorage);
                      } else if (allStorages[index] is LocalStorage) {
                        showLocalDialog(context,
                            storage: allStorages[index] as LocalStorage);
                      }
                      break;
                    case StorageOptions.remove:
                      useStorageStore().removeStorage(allStorages[index]);
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
