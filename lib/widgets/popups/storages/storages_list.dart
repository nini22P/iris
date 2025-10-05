import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/widgets/dialogs/show_folder_dialog.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/widgets/dialogs/show_ftp_dialog.dart';
import 'package:iris/widgets/dialogs/show_webdav_dialog.dart';
import 'package:path/path.dart' as p;

class StoragesList extends HookWidget {
  const StoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final localStoragesFuture =
        useMemoized(() async => await getLocalStorages(context), []);
    final localStorages = useFuture(localStoragesFuture).data ?? [];

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
        subtitle:
            allStorages[index].name.contains(allStorages[index].basePath[0])
                ? null
                : () {
                    String? subtitle;

                    switch (allStorages[index].type) {
                      case StorageType.internal:
                      case StorageType.network:
                      case StorageType.usb:
                      case StorageType.sdcard:
                        subtitle =
                            p.normalize(allStorages[index].basePath.join('/'));
                        break;
                      case StorageType.webdav:
                        final storage = allStorages[index] as WebDAVStorage;
                        subtitle =
                            'http${storage.https ? 's' : ''}://${storage.host}${storage.port.isNotEmpty && storage.port != '80' && storage.port != '443' ? ':${storage.port}' : ''}${storage.basePath.join('/')}';
                        break;
                      case StorageType.ftp:
                        final storage = allStorages[index] as FTPStorage;
                        subtitle =
                            'ftp://${storage.username.isNotEmpty ? '${storage.username}@' : ''}${storage.host}:${storage.port}${storage.basePath.join('/')}';
                        break;
                      case StorageType.none:
                        break;
                    }

                    return subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                          );
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
                      switch (allStorages[index].type) {
                        case StorageType.internal:
                        case StorageType.network:
                        case StorageType.usb:
                        case StorageType.sdcard:
                          showFolderDialog(context,
                              storage: allStorages[index] as LocalStorage);
                          break;
                        case StorageType.webdav:
                          showWebDAVDialog(context,
                              storage: allStorages[index] as WebDAVStorage);
                          break;
                        case StorageType.ftp:
                          showFTPDialog(context,
                              storage: allStorages[index] as FTPStorage);
                          break;
                        case StorageType.none:
                          break;
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
